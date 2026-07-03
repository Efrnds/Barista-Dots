#!/usr/bin/env python3
import os

def read_val(path):
    try:
        with open(path, 'r') as f:
            return int(f.read().strip())
    except:
        return 0

p0 = read_val("/sys/class/power_supply/BAT0/power_now")
p1 = read_val("/sys/class/power_supply/BAT1/power_now")
ac = read_val("/sys/class/power_supply/AC/online")

total_w = (p0 + p1) / 1000000.0

if ac == 1:
    if total_w > 0.5:
        print(f"⚡ +{total_w:.1f}W")
    else:
        print("🔌 AC")
else:
    print(f"🔋 -{total_w:.1f}W")
