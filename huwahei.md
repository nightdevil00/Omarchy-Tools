# Huawei Bluetooth Audio

Date: 2026-09-25

## Device

- Device: HUAWEI FreeBuds SE 3
- Bluetooth address: `00:8A:55:D4:B4:AB`
- PipeWire card: `bluez_card.00_8A_55_D4_B4_AB`
- Audio stack: PipeWire 1.6.9 with WirePlumber 0.5.17

## Change

The Huawei headset was negotiating AAC by default. A Huawei-only WirePlumber profile-priority rule was added at:

`~/.config/wireplumber/wireplumber.conf.d/huawei-sbc.conf`

The rule matches the Huawei card and prioritizes the standard SBC profile:

```conf
device.profile.priority.rules = [
  {
    matches = [
      {
        device.name = "bluez_card.00_8A_55_D4_B4_AB"
      }
    ]
    actions = {
      update-props = {
        priorities = [ "a2dp-sink-sbc" ]
      }
    }
  }
]
```

This changes only the Huawei card; the other Bluetooth devices keep their existing codec preferences.

## Application and verification

- Restarted WirePlumber to load the rule.
- Selected the `a2dp-sink-sbc` profile so WirePlumber saved it as the device preference.
- Re-paired and trusted the headset after a verification disconnect removed its old pairing.
- Restored the previous headset volume level of approximately 69%.
- Verified the active sink with `wpctl inspect` and `pactl list sinks`.
- Confirmed `api.bluez5.codec = "sbc"` after reconnecting and after a WirePlumber restart.
