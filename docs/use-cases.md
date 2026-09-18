# Use cases

What the generated Home Assistant package does day to day, and how to turn on the optional parts. Entity IDs use `<person>` and `<chair>` as in [testing.md](testing.md); your `INSTALL.md` has the real ones.

## Entities

| Entity | Meaning |
| --- | --- |
| `binary_sensor.<chair>_occupied` | Device reading, filtered: on shortly after sitting, off 90 s (default) after standing. Unavailable while the device is offline. |
| `binary_sensor.<chair>_pad_cable` | Problem sensor: on when the pad cable is cut or the pad unplugged. |
| `binary_sensor.<person>_seated` | Like Occupied, but holds the last known state through outages and pad faults. Use this for timing and dashboards. |
| `sensor.<person>_sat_down` | When the person last sat down. |
| `sensor.<person>_last_got_up` | When the person last got up. |
| `sensor.<person>_minutes_seated` | Minutes in the chair this sitting, 0 when up. |
| `binary_sensor.<person>_check_due` | On when a check is due. Drives the reminders. |

The timestamps survive Home Assistant restarts and device reboots. After an outage they only update if the person's state changed while the device was offline, and then they show the reconnect time.

## Reminders (main feature)

While seated, a reminder arrives each time the interval passes since sitting down or since the last **Handled**. Ignored reminders escalate to a critical alert and a `recliner_escalation` event after the escalation delay, and repeat until handled or the person gets up. Nothing fires outside your active hours; at the end of the day an active reminder clears, and next morning it starts again if still due.

Turn on with `<person> reminders enabled`. Set `<person> reminder interval` and `<person> escalation delay` to the care plan first: both start at 1 minute after installation.

**Escalating beyond the phone:** another automation, assistant or pager can listen for `recliner_escalation` (with `event_data.person`) and stand down on `recliner_escalation_resolved`. If you gave `generate.py` a webhook URL, the same escalation and stand-down are also sent there as JSON: `{"person": ..., "event": "escalation" or "resolved", "message": ...}`.

## Alert when they get up

A notification each time the person leaves the chair, for example to go and help with a walker. Turn on `<person> got up alerts enabled`.

It arrives after the off delay (default 90 s), which stops leaning forward or shifting from counting. A sensor outage or a broken pad never triggers it.

To test: sit for at least the on delay, stand, and wait for the notification. Then sit, lean forward for a few seconds, and sit back: nothing should arrive.

If the delay is too long, watch a few days of Pad Raw history to see how long shifts actually last, then re-run `generate.py` with a smaller `delayed_off` and reinstall the firmware over WiFi. This also makes reminders clear sooner.

## Time since up

No setup needed. Add `sensor.<person>_minutes_seated`, `sensor.<person>_sat_down` and `sensor.<person>_last_got_up` to a dashboard. Home Assistant shows timestamps as relative times, like "Sat down 2 hours ago".

## Long sit alert, daytime only

One notification per sitting when the person has not got up for the hours you chose (default 4), only within active hours. If a sitting passes the threshold overnight, the alert arrives when active hours start. Turn on `<person> <N> hour seated alert enabled`.

To test without waiting hours: in the generated package, temporarily change both `above:` values in the long sit automation to `1`, reload automations, sit for 2 minutes, and confirm the alert. Then change them back.

## Dashboard

Settings > Dashboards > Add dashboard, then add cards. Tile cards show state as text as well as color.

```yaml
type: vertical-stack
cards:
  - type: tile
    entity: binary_sensor.<person>_seated
    name: In the chair
  - type: tile
    entity: sensor.<person>_minutes_seated
    name: Minutes seated
  - type: tile
    entity: sensor.<person>_last_got_up
    name: Last got up
  - type: tile
    entity: binary_sensor.<chair>_pad_cable
    name: Pad
  - type: history-graph
    title: Today
    hours_to_show: 24
    entities:
      - entity: binary_sensor.<person>_seated
```

Also useful: a Logbook card filtered to `binary_sensor.<chair>_occupied` for a text list of sit and stand times, the device's WiFi Signal sensor, and tiles for the enable toggles.

## Daily totals

The History stats integration (Settings > Devices & services > Add integration > History stats) can count time seated today (type: time, entity `binary_sensor.<person>_seated`, state on) and times up today (type: count, entity `binary_sensor.<chair>_occupied`, state off). Start `{{ today_at() }}`, end `{{ now() }}`. The count includes the device reconnecting while the person is up, so treat it as approximate.

## Longer history

Home Assistant keeps detailed history for 10 days by default. Raise it in `configuration.yaml`:

```yaml
recorder:
  purge_keep_days: 60
```

`sensor.<person>_minutes_seated` also records long-term statistics, which a Statistics graph card can show indefinitely.

## Your own dashboard app

Read from Home Assistant rather than the device: it has the derived sensors, and the device's API is meant for Home Assistant.

- **Live state:** the WebSocket API, for example with the `home-assistant-js-websocket` package (`createLongLivedTokenAuth`, `createConnection`, `subscribeEntities`).
- **History:** `GET /api/history/period/<start>?filter_entity_id=binary_sensor.<person>_seated&minimal_response&no_attributes` with `Authorization: Bearer <token>`.
- **Token:** your profile > Security > Long-lived access tokens. A browser app calling Home Assistant directly needs its origin in `http: cors_allowed_origins`, and exposes the token in page code; a small local backend that holds the token is safer.
- **Accessibility:** show state in words ("In the chair, 2 h 15 min"), not color alone; announce changes with an `aria-live="polite"` region; make an offline sensor obvious ("Sensor offline, last known: seated").
