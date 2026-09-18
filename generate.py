#!/usr/bin/env python3
"""Generate personalized ESPHome and Home Assistant files for a recliner
occupancy sensor.

Interactive:        python3 generate.py
From saved answers: python3 generate.py --config output/<name>/answers.json

Writes to output/<person_id>/ (git-ignored). Standard library only.
"""

import argparse
import base64
import getpass
import json
import re
import secrets
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TEMPLATES = ROOT / "templates"

# Question order, prompt text, and default. Stored in answers.json (no secrets).
QUESTIONS = [
    ("person_name", "Name of the person who uses the chair, as shown in alerts", "Grandma"),
    ("caregiver_name", "Name of the caregiver who gets the alerts", "the caregiver"),
    ("chair_name", "Name for the chair sensor device", "Recliner"),
    ("notify_action", "Home Assistant notify action for your phone (Developer tools > Actions, type notify.mobile_app)", "notify.mobile_app_your_phone"),
    ("window_start", "Reminders and alerts start each day at (HH:MM, 24 hour)", "09:00"),
    ("window_end", "Reminders and alerts stop each day at (HH:MM, 24 hour)", "22:00"),
    ("long_sit_hours", "Long sit alert after how many hours seated", "4"),
    ("snooze_minutes", "Snooze button length in minutes", "15"),
    ("delayed_on", "Seconds seated before counting as occupied", "10"),
    ("delayed_off", "Seconds empty before counting as up (covers shifting and leaning)", "90"),
    ("webhook_url", "Optional webhook URL to POST escalations to (blank for none)", ""),
]


def slug(text, sep="_"):
    """Match Home Assistant's slugify for plain ASCII names."""
    s = re.sub(r"[^a-z0-9]+", sep, text.lower()).strip(sep)
    return s


def fail(msg):
    sys.exit(f"error: {msg}")


def validate(a):
    for key in ("person_name", "caregiver_name", "chair_name"):
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9 '\-]*", a[key]):
            fail(f"{key} must use plain letters, digits, spaces, hyphens or apostrophes: {a[key]!r}")
    if len(a["chair_name"]) > 23:
        fail("chair_name must be 23 characters or fewer (it becomes part of the device's fallback WiFi name)")
    if not slug(a["person_name"]) or not slug(a["chair_name"]):
        fail("person_name and chair_name need at least one letter or digit")
    if not re.fullmatch(r"notify\.[a-z0-9_]+", a["notify_action"]):
        fail(f"notify_action should look like notify.mobile_app_pixel_8: {a['notify_action']!r}")
    times = []
    for key in ("window_start", "window_end"):
        m = re.fullmatch(r"([01]\d|2[0-3]):([0-5]\d)", a[key])
        if not m:
            fail(f"{key} must be HH:MM in 24 hour time: {a[key]!r}")
        times.append(int(m[1]) * 60 + int(m[2]))
    if times[0] >= times[1]:
        fail("window_start must be earlier in the day than window_end (overnight windows are not supported)")
    for key, lo, hi in (("long_sit_hours", 1, 24), ("snooze_minutes", 1, 240),
                        ("delayed_on", 1, 120), ("delayed_off", 5, 900)):
        try:
            v = int(a[key])
        except ValueError:
            fail(f"{key} must be a whole number: {a[key]!r}")
        if not lo <= v <= hi:
            fail(f"{key} must be between {lo} and {hi}: {v}")
    if a["webhook_url"] and not re.fullmatch(r"https?://\S+", a["webhook_url"]):
        fail(f"webhook_url must start with http:// or https://: {a['webhook_url']!r}")


def ask(answers):
    print("Answer each question, or press Enter to accept the [default].\n")
    for key, prompt, default in QUESTIONS:
        current = answers.get(key, default)
        reply = input(f"{prompt} [{current}]: ").strip()
        answers[key] = reply or current
    return answers


def webhook_blocks(a, pid):
    """YAML for the optional webhook, or empty strings."""
    if not a["webhook_url"]:
        return {"webhook_rest_command": "", "webhook_escalate_step": "", "webhook_resolved_step": ""}
    url = a["webhook_url"].replace('"', '\\"')
    rest = f"""# ---------------------------------------------------------------------------
# Escalation webhook
# ---------------------------------------------------------------------------
rest_command:
  {pid}_escalation_webhook:
    url: "{url}"
    method: post
    content_type: application/json
    payload: >
      {{{{ {{"person": "{pid}", "event": event, "message": message}} | tojson }}}}

"""
    escalate = f"""
      # Webhook last, so a failed request can never block the phone alert
      - action: rest_command.{pid}_escalation_webhook
        continue_on_error: true
        data:
          event: escalation
          message: >
            Seated {{{{ states('sensor.{pid}_minutes_seated') }}}} min and not acknowledged.
"""
    resolved = f"""      - action: rest_command.{pid}_escalation_webhook
        continue_on_error: true
        data:
          event: resolved
          message: Check handled or no longer seated.
"""
    return {"webhook_rest_command": rest, "webhook_escalate_step": escalate,
            "webhook_resolved_step": resolved}


def render(name, values):
    text = (TEMPLATES / name).read_text()
    # Block placeholders sit alone on a line; drop the whole line when empty.
    for key in ("webhook_rest_command", "webhook_escalate_step", "webhook_resolved_step"):
        text = text.replace(f"@@{key}@@\n", values[key])
    for key, value in values.items():
        text = text.replace(f"@@{key}@@", str(value))
    leftover = re.findall(r"@@\w+@@", text)
    if leftover:
        fail(f"template {name} has unfilled placeholders: {sorted(set(leftover))}")
    return text


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--config", type=Path, help="answers.json from a previous run (skips questions)")
    ap.add_argument("--out", type=Path, help="output directory (default: output/<person_id>)")
    ap.add_argument("--wifi", action="store_true", help="also ask for WiFi SSID and password for secrets.yaml")
    args = ap.parse_args()

    answers = {key: default for key, _, default in QUESTIONS}
    if args.config:
        answers.update(json.loads(args.config.read_text()))
    else:
        answers = ask(answers)
    validate(answers)

    pid = slug(answers["person_name"])
    chair_id = slug(answers["chair_name"])
    device_name = slug(answers["chair_name"], "-") + "-sensor"
    secret_prefix = slug(device_name)
    long_sit = int(answers["long_sit_hours"])
    snooze = int(answers["snooze_minutes"])

    values = {
        "person": answers["person_name"],
        "pid": pid,
        "PID": pid.upper(),
        "caregiver": answers["caregiver_name"],
        "chair_name": answers["chair_name"],
        "chair_id": chair_id,
        "device_name": device_name,
        "secret_prefix": secret_prefix,
        "notify": answers["notify_action"],
        "window_start": answers["window_start"],
        "window_end": answers["window_end"],
        "long_sit_hours": long_sit,
        "long_sit_threshold": long_sit * 60 - 1,
        "snooze_minutes": snooze,
        "snooze_seconds": snooze * 60,
        "delayed_on": int(answers["delayed_on"]),
        "delayed_off": int(answers["delayed_off"]),
    }
    values.update(webhook_blocks(answers, pid))

    out = args.out or ROOT / "output" / pid
    (out / "esphome").mkdir(parents=True, exist_ok=True)
    (out / "homeassistant").mkdir(parents=True, exist_ok=True)

    esphome_file = out / "esphome" / f"{device_name}.yaml"
    package_file = out / "homeassistant" / f"{pid}_recliner.yaml"
    esphome_file.write_text(render("esphome.yaml.tmpl", values))
    package_file.write_text(render("ha_package.yaml.tmpl", values))
    (out / "INSTALL.md").write_text(render("INSTALL.md.tmpl", values))

    # Secrets: keep existing keys on re-runs so the device and HA stay paired.
    secrets_file = out / "esphome" / "secrets.yaml"
    existing = {}
    if secrets_file.exists():
        for line in secrets_file.read_text().splitlines():
            m = re.match(r'(\w+):\s*"(.*)"\s*$', line)
            if m:
                existing[m[1]] = m[2]
    api_key = existing.get(f"{secret_prefix}_api_key") or base64.b64encode(secrets.token_bytes(32)).decode()
    fallback = existing.get(f"{secret_prefix}_fallback_password") or secrets.token_urlsafe(12)
    ssid = existing.get("wifi_ssid", "YOUR_WIFI_NAME")
    wifi_pw = existing.get("wifi_password", "YOUR_WIFI_PASSWORD")
    if args.wifi:
        ssid = input(f"WiFi network name (2.4 GHz) [{ssid}]: ").strip() or ssid
        wifi_pw = getpass.getpass("WiFi password (hidden, Enter to keep current): ") or wifi_pw
    for v in (ssid, wifi_pw):
        if '"' in v or "\\" in v:
            fail("WiFi name and password cannot contain double quotes or backslashes here; edit secrets.yaml by hand")
    secrets_file.write_text(
        "# ESPHome secrets. Private: never commit or share this file.\n"
        "# If you already have an ESPHome secrets.yaml, copy these lines into it.\n"
        f'wifi_ssid: "{ssid}"\n'
        f'wifi_password: "{wifi_pw}"\n'
        f'{secret_prefix}_api_key: "{api_key}"\n'
        f'{secret_prefix}_fallback_password: "{fallback}"\n'
    )
    secrets_file.chmod(0o600)

    (out / "answers.json").write_text(json.dumps(answers, indent=2) + "\n")

    print(f"\nWrote files to {out}:")
    for f in (esphome_file, secrets_file, package_file, out / "INSTALL.md", out / "answers.json"):
        print(f"  {f.relative_to(out)}")
    if "YOUR_WIFI" in ssid + wifi_pw:
        print("\nNext: put your WiFi name and password in esphome/secrets.yaml (or re-run with --wifi).")
    print(f"Then follow {out / 'INSTALL.md'}.")


if __name__ == "__main__":
    main()
