# Recliner Occupancy Sensor

A pressure pad under a recliner's seat cover tells Home Assistant when someone sits down and gets up. Home Assistant then reminds a caregiver to check on them, for a bathroom trip, a change, or a stretch, before they have been sitting too long. It works while the person is asleep and completely still, which motion sensors do not.

It was built for an elderly family member who uses a lift recliner and a walker and sometimes falls asleep in the chair, cared for by someone working from home in another room.

> **Safety note.** This is an assistive reminder tool. It is not a medical device, it does not detect falls, and it is not a substitute for supervision or professional care. It can fail: power cuts, WiFi outages, phone notification settings, Home Assistant problems, or a pad that has moved. It is designed to fail loudly where it can, with alerts when the sensor goes offline or the pad is disconnected, but the caregiver remains responsible. Test it before relying on it, and keep checking it.

![Wiring diagram](docs/wiring.svg)

## What it does

- **Reminders while seated,** at an interval you set, with **Handled** and **Snooze** buttons on the phone notification.
- **Escalation** to a critical alert, which breaks through silent mode, if a reminder is ignored. An event and an optional webhook let another system, such as an assistant or pager, escalate further.
- **Quiet hours:** no reminders overnight, so nobody is woken while the person sleeps in the chair.
- **Optional alerts** when the person gets up, and after a long sit (default 4 hours, daytime only).
- **Fails loudly:** an alert if the sensor goes offline, and another if the pad cable is cut or unplugged. Without that check, a broken pad would look like an empty chair and reminders would silently stop.
- **Rides out glitches:** a WiFi drop, reboot or pad fault keeps the last known state instead of cancelling a reminder.

## How it works

- **Pad:** a replacement chair alarm pad, the kind sold for caregiver monitors. It is a membrane switch: sitting presses two conductive layers together. Many pads run each layer out and back on two wires; this project uses the spare wire to detect a broken cable.
- **Board:** a Seeed XIAO ESP32S3 running ESPHome reads the pad on two pins, filters out shifting and leaning, and reports to Home Assistant over WiFi.
- **Home Assistant:** a generated package tracks when the person sat down and got up, decides when a check is due, and sends the notifications.
- **Case:** a 3D printed case holds the board, antenna and cable splices, with strain relief, attached to the chair's base with hook-and-loop.

## What you need

A Seeed XIAO ESP32S3 with its antenna, a chair sensor pad, a 1 kΩ resistor, a USB power adapter, a 3D printed case, basic soldering tools, and Home Assistant with the companion app. Full list: [docs/bom.md](docs/bom.md).

## Quick start

1. **Print** the case: [enclosure/](enclosure/README.md).
2. **Identify** your pad's wires: [docs/identify-your-pad.md](docs/identify-your-pad.md).
3. **Generate** your configuration: `python3 generate.py`. It asks for names, your phone's notify action and your preferred hours, then writes the ESPHome config, a secrets file with fresh encryption keys, the Home Assistant package, and an `INSTALL.md` written for your setup.
4. **Build:** [docs/build-guide.md](docs/build-guide.md). Flash and test the board before soldering, and test the pad on a breadboard before making it permanent.
5. **Install and test:** follow your generated `INSTALL.md`, then [docs/testing.md](docs/testing.md).

## Documentation

| Doc | Covers |
| --- | --- |
| [docs/bom.md](docs/bom.md) | Parts, tools and software |
| [docs/identify-your-pad.md](docs/identify-your-pad.md) | Finding the switch and check wires, hands-free measuring, other pad types |
| [docs/build-guide.md](docs/build-guide.md) | Step by step build and installation |
| [docs/testing.md](docs/testing.md) | Full test plan, alerting several phones |
| [docs/use-cases.md](docs/use-cases.md) | Features, optional alerts, dashboards, your own app |
| [docs/troubleshooting.md](docs/troubleshooting.md) | WiFi, stuck readings, Home Assistant issues |
| [enclosure/README.md](enclosure/README.md) | Printing and adjusting the case |

## Repository layout

```
generate.py          configuration generator (Python 3, standard library only)
templates/           ESPHome, Home Assistant and install guide templates
examples/            example answers for generate.py --config
enclosure/           OpenSCAD source and printable STLs
docs/                build, test and usage documentation
output/              your generated files (git-ignored, contains secrets)
```

## Status

Built and in use in one home, with one pad model: the Smart Caregiver 10 x 15 in replacement chair sensor pad. The hardware, firmware and in-chair behavior are tested. The Home Assistant package passes Home Assistant's own configuration check and matches the logic of the running installation. Reports from other pads and chairs are welcome.

## License

- **Code and configuration** (`generate.py`, `templates/`, `examples/`): [MIT](LICENSE).
- **Enclosure design, documentation and images** (`enclosure/`, `docs/`, this README): [CC BY-SA 4.0](LICENSE-CC-BY-SA-4.0.md).
