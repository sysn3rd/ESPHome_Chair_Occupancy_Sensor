# Bill of materials

Quantities are for one chair. Nothing here is exotic; the only part that varies between builds is the pad, so read [identify-your-pad.md](identify-your-pad.md) before buying anything else if you already have one.

## Electronics

| Part | Qty | Notes |
| --- | --- | --- |
| Seeed Studio XIAO ESP32S3 | 1 | The plain version, not the Sense. It ships with the U.FL FPC antenna, which is **required**: without it the board sees the network at about -90 dBm and cannot connect. Consider buying 2; the castellated pads lift if reworked too often. |
| Chair sensor pad, corded, 10 x 15 in | 1 | **Tested:** Replacement 10in x 15in Chair Sensor Pad by Smart Caregiver, UPC 812293010372 ([Amazon B01N0P2J6X](https://www.amazon.com/dp/B01N0P2J6X)). A replacement pad for their TL-2100 series monitors, with a 4-wire modular plug. Other brands usually work, but wire colors and layout vary: see [identify-your-pad.md](identify-your-pad.md). |
| 1 kΩ resistor, 1/4 W | 2 | One on the switch wire (D3) and one on the check wire (D4), protecting the pins from static on the long pad cable. |
| USB-C cable | 1 | Must carry data for the first flash. After that any cable works. |
| 5 V USB power adapter, 1 A or more | 1 | Wall power only. WiFi drains a battery in under a day. |
| Stranded hookup wire, 24 to 26 AWG | about 30 cm each of 3 colors | Match the pad colors if you can; it makes checking easier. |
| Heat shrink tubing | assorted, 2 to 5 mm | For every splice and over both resistors. |

## Enclosure and mounting

| Part | Qty | Notes |
| --- | --- | --- |
| PLA filament | about 25 g | Base and lid. See [../enclosure/README.md](../enclosure/README.md). |
| M3 self-tapping screws, 8 or 10 mm | 4 | Lid to base. Drive until just snug; PLA strips easily. |
| Double-sided foam tape | small piece | Holds the board on its platform. |
| Zip ties, 2.5 mm wide | 3 | One anchors the pad cable inside the case, two strain relieve the USB cable outside. |
| Adhesive hook-and-loop (Velcro) | about 5 x 7 cm | Mounts the case to the chair's base fabric. |

## Tools

| Tool | Why |
| --- | --- |
| 3D printer, or a print service | Enclosure |
| Soldering iron and solder, flux | Board and splices. Chisel tip, about 320 °C for leaded solder, 350 to 370 °C for lead-free. |
| Multimeter | Identifying the pad's wires |
| Solderless breadboard and solid-core jumper wires | Hands-free measuring and a no-solder test before the permanent build. Strongly recommended. |
| Helping hands or alligator clips | Hold work steady while soldering |
| Wire strippers, flush cutters | General |
| Computer with a USB port | First flash |

## Software

| Software | Notes |
| --- | --- |
| Home Assistant | With the companion app on each caregiver's phone |
| ESPHome | ESPHome Device Builder (add-on or desktop) or the `esphome` command line tool |
| Python 3.8 or newer | Runs `generate.py`. Standard library only, nothing to install. |
