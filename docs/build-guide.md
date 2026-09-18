# Build guide

Order matters: prove each stage works before making anything permanent. Flash and test the board before soldering the pad, and test the pad on a breadboard before soldering it to the board.

Parts and tools: [bom.md](bom.md).

## 1. Print the enclosure

Print `enclosure/base.stl` and `enclosure/lid.stl` in PLA with no supports. Details and adjustable dimensions are in [../enclosure/README.md](../enclosure/README.md). If you are unsure about your printer's tolerances, print `test.stl` first: it is only the USB-C end, and shows whether your cable's plug seats fully.

## 2. Identify the pad's wires

Follow [identify-your-pad.md](identify-your-pad.md). You need to know three wires by the end:

| Role | Tested pad | Board pin |
| --- | --- | --- |
| Switch wire (one end of layer A) | red | D3, through the 1 kΩ resistor |
| Return wire (one end of layer B) | green | GND |
| Check wire (other end of layer B) | yellow | D4, through a second 1 kΩ resistor |
| Unused (other end of layer A) | black | none, insulate |

## 3. Generate your configuration

```
python3 generate.py
```

It asks for the person's name, the chair's name, your phone's notify action (find it in Home Assistant under Developer tools > Actions by typing `notify.mobile_app`), the hours when alerts are allowed, and a few timings. Press Enter to accept a default. Files are written to `output/<name>/`, along with an `INSTALL.md` that uses your names throughout. Keep `answers.json`: re-running with `--config` changes settings without changing your encryption keys.

## 4. Flash and add the board, before any soldering

1. Clip the FPC antenna onto the XIAO's U.FL socket: line it up square, press straight down until it clicks. Do this unpowered. It is only rated for about 30 connections, so attach it once and leave it.
2. Follow sections 1 and 2 of your generated `INSTALL.md` to flash the board and add it to Home Assistant.
3. **Jumper test.** Touch a wire between D3 and GND for 20 seconds, then remove it. In Home Assistant, `Pad Raw` turns on immediately, `Occupied` turns on after the delay you chose (default 10 s), and `Occupied` turns off after the release delay (default 90 s). `Pad Cable` shows Problem at this stage, because nothing is on D4 yet. That is expected.

If the board does not join WiFi, check the antenna first. See [troubleshooting.md](troubleshooting.md).

## 5. Test the pad on a breadboard

Before soldering, wire the pad to the board through the breadboard: switch wire to D3 and check wire to D4, each through a resistor, and return wire to GND. Then, watching Home Assistant:

1. Pad empty: `Pad Raw` off, `Pad Cable` OK.
2. Press the pad: `Pad Raw` on, `Occupied` on after the delay.
3. Release: `Occupied` off after the release delay.
4. Pull the check wire or the return wire: `Pad Cable` shows Problem within 2 seconds. Put it back.

If any step fails, stop and see [troubleshooting.md](troubleshooting.md). Everything after this point is harder to undo.

## 6. Solder the permanent wiring

Unplug the USB cable first.

1. **Board wires.** Solder three short hookup wires to the XIAO: one to D3, one to D4, one to GND. D3 and D4 sit next to each other on one edge; GND is on the opposite edge, second from the USB-C end. Confirm against the labels printed on your board. Tin the pad and the wire first, then join them with a 2 to 3 second touch. Lingering lifts pads.
2. **Resistors.** Splice a 1 kΩ resistor into the D3 wire and another into the D4 wire, with heat shrink over each joint and each resistor body.
3. **Splices to the pad.** Slide heat shrink on first, then splice each pad wire to its board wire. Keep the joints staggered so they cannot touch each other, and shrink the tubing over each.
4. **Unused wire.** Trim it and cover the end with heat shrink so it cannot touch anything.
5. Plug in and repeat the four breadboard checks from step 5.

If fine motor work is difficult, clamp everything in helping hands or alligator clips so neither hand holds the work, and pre-tin every wire before joining. Soldered splices are more forgiving than crimped connectors: the JST PH crimp terminals this enclosure was first drawn for are small and fiddly, and the splices fit in the same space.

## 7. Assemble

![Inside the enclosure](images/enclosure-layout.png)

1. **Board:** foam tape on the raised platform, board pressed down with the USB-C port square in its opening. The two corner stops at the far end set its position.
2. **Antenna:** peel and stick flat to the floor of the antenna bay, beyond the low divider. Run the coax through the gap in the divider without kinking it.
3. **Pad cable:** lay the cable in the open notch in the end wall so it rides on top of the anchor block. Thread a zip tie through the tunnel under the block and around the cable. **Snug, not crushing**: the cable should not slide, but a flat cable crushed hard can short its conductors.
4. **Splices:** lay them between the two rails, away from the screw posts.
5. **Power cable:** plug in, then zip tie the cable to the tab outside the USB end using its two slots, so a tug never reaches the board's connector.
6. **Lid:** lower it straight down, check no wire is pinched at the rim, and drive the four screws until just snug.
7. Stick the hook-and-loop to the underside.

## 8. Install at the chair

- **Pad:** under the seat cover, flat, where the person actually sits. It must not bridge the fold between seat and backrest.
- **Case:** on the back of the chair's base fabric, on a part that does not move with the lift or recline mechanism.
- **Cables:** leave slack for the full lift and recline travel, and route both cables away from the scissor mechanism and footrest hinge.
- **WiFi:** check the device's `WiFi Signal` sensor at the chair. Better than -70 dBm is solid; worse than -80 dBm is risky.

## 9. Home Assistant and testing

Follow sections 3 to 5 of your `INSTALL.md`, then work through [testing.md](testing.md) completely before relying on it.
