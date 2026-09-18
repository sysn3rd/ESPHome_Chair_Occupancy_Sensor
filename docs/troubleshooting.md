# Troubleshooting

## WiFi

**Device never joins the network; logs show the network at -85 to -96 dBm and "Auth Expired" or "Probe Request Unsuccessful".** The FPC antenna is not attached. The XIAO ESP32S3 has no usable antenna without it. Unplug, press the antenna's U.FL plug straight down onto the socket until it clicks, and power up again. Typical signal with it attached: -50 to -65 dBm.

**Device creates a "<Chair> Fallback" network.** It could not join your WiFi. Check the antenna, that the network is 2.4 GHz, and the name and password in `secrets.yaml`. You can join the fallback network from a phone (password is in `secrets.yaml`) to enter WiFi details.

**Signal worse than about -75 dBm at the chair.** Move the case to a different side of the chair, keep the antenna flat and away from the metal frame, or add a closer access point.

## Flashing

**Board not detected over USB.** Use a data cable, not a charge-only one. Unplug, hold the BOOT button, plug in, then release.

## Pad readings

**Occupied (and Pad Raw) stuck on with nobody in the chair.** Almost always both ends of the same conductor are wired to D3 and GND, which ties D3 to ground. Re-identify the wires with [identify-your-pad.md](identify-your-pad.md). To split the problem, unplug the board, disconnect the GND wire, and power up again: if Pad Raw goes off, the short is in the pad or cable; if it stays on, look for a solder bridge on the board. Also check for a zip tie crushing the pad cable.

**Occupied never turns on.** The wire pair is wrong, the pad is normally closed (see [identify-your-pad.md](identify-your-pad.md)), the resistor joint is broken, or the pad needs more weight in that spot. Watch Pad Raw while pressing firmly.

**Pad Raw flickers while seated.** Normal in small amounts; the Occupied filter absorbs it. Constant flicker means the pad sits where the person only partly rests: move it to where they actually land, flat and clear of the seat and backrest fold.

**Pad Cable always shows Problem.** D4 is not connected, or it is connected to the wrong conductor. The check wire must be the other end of the same conductor as the GND wire. For a two-wire pad, connect D4 straight to GND.

**Meter readings jump around.** Probes on thin stranded wire give unreliable contact, and a slipping probe reads "open". Use the breadboard method in [identify-your-pad.md](identify-your-pad.md), or clip the probes on.

## Home Assistant

**Entity IDs end in `_2`.** An older device with the same name is still registered, for example after swapping boards. Delete the old device's ESPHome entry, then re-add the new one.

**After replacing the board, Home Assistant still shows the old one as unavailable.** The integration remembers the old board's address and hardware ID. Use Reconfigure on the ESPHome entry with host `<device>.local`, or delete the entry and add it again with the same encryption key.

**Check configuration reports errors in the package.** Re-generate it rather than editing by hand; the generator validates your answers. If you edited the file, compare with a fresh copy.

**No notifications at all.** Test the notify action alone from Developer tools > Actions. If that fails, the action name is wrong or the companion app is not registered. Every alert in the package uses the same action.

**Reminders arrive but the critical alert is silent.** iOS: allow Critical Alerts for the Home Assistant app. Android: set the `<person>_urgent` notification channel to high importance with sound; the channel appears after the first escalation.

**Nothing happens in the evening or early morning.** Reminders and the long sit alert only run within active hours (default 09:00 to 22:00). This is intentional, so nobody is woken while the person sleeps in the chair.
