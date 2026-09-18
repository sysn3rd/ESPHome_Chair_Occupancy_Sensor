# Testing

Run all of this before relying on the sensor. A reminder that silently fails to arrive is the failure this project exists to prevent, and most of the ways that can happen are in Home Assistant and phone settings, not the hardware.

Names below use `<person>` for your person ID (for example `grandma`) and `<chair>` for your chair ID (for example `recliner`). Your generated `INSTALL.md` has the exact entity IDs. Tests with timings must run inside your active hours (default 09:00 to 22:00).

## Before you start

1. **Notify action works.** Developer tools > Actions, run your notify action with a test message. It must arrive on the phone.
2. **Critical alerts allowed** (iOS): Settings > Notifications > Home Assistant > Critical Alerts on.
3. **Short timings:** set `<person> reminder interval` to 2 and `<person> escalation delay` to 1. Turn on `<person> reminders enabled`.
4. **Watch events:** in a browser tab, Developer tools > Events, listen to `recliner_escalation`, and in another tab `recliner_escalation_resolved`.

## 1. Device

| Action | Expected |
| --- | --- |
| Sit on the pad | `binary_sensor.<chair>_pad_raw` on immediately, `binary_sensor.<chair>_occupied` on after the on delay, `binary_sensor.<person>_seated` on |
| Shift, lean forward, recline, use the lift | Occupied stays on. Pad Raw may flicker; that is what the filter is for |
| Stand up | Occupied off after the off delay (default 90 s) |
| Drop into the chair hard, the way the person does | Occupied on after the on delay, no bounce |

## 2. Reminder cycle

Sit and leave the phone alone.

| Time after sitting | Expected |
| --- | --- |
| about 2 min | "Time to check on `<Person>`" notification with Handled and Snooze buttons |
| about 3 min | Critical "`<Person>` check overdue" alert, and a `recliner_escalation` event |
| every minute after | Reminder, then escalation, repeating |

## 3. Each way out

| Action | Expected |
| --- | --- |
| Tap **Handled** | Notification clears, `recliner_escalation_resolved` fires, next reminder about 2 min later if still seated |
| Tap **Snooze** | Notification clears, no reminder until the snooze ends |
| Stand up mid-cycle | After the off delay, notification clears and `recliner_escalation_resolved` fires |
| Turn off reminders enabled mid-cycle | Notification clears |

## 4. Offline

| Action | Expected |
| --- | --- |
| Unplug the device for 3 minutes | "sensor offline" alert |
| Unplug while seated with a reminder active | `binary_sensor.<person>_seated` stays on and reminders keep coming |
| Then stand up, plug back in | Seated turns off once the device reconnects |

## 5. Pad cable fault

| Action | Expected |
| --- | --- |
| While seated, disconnect the check wire (D4) or the return wire | `binary_sensor.<chair>_pad_cable` on within 2 s, "pad disconnected" alert about 10 s later, Seated stays on, no "got up" alert |
| Reconnect | Pad Cable clears, `sensor.<person>_sat_down` keeps its original time |

## 6. Optional alerts

If you enabled them, test the got up alert and the long sit alert as described in [use-cases.md](use-cases.md).

## 7. Real settings

Set the reminder interval and escalation delay to the care plan, keep reminders enabled, and watch a few days of `binary_sensor.<chair>_pad_raw` history. You are checking that the pad reads reliably where the person actually sits, including when asleep and still.

## Alerting more than one phone

Create a notify group in `configuration.yaml`, restart, then re-run `python3 generate.py --config output/<person>/answers.json` after changing `notify_action` in that file to `notify.family_phones`:

```yaml
notify:
  - platform: group
    name: family_phones
    services:
      - action: mobile_app_first_phone
      - action: mobile_app_second_phone
```

Titles, messages, buttons and clearing all pass through to every phone in the group. Older Home Assistant versions use `service:` instead of `action:` in the group entries.
