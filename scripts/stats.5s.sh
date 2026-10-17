#!/usr/bin/env bash
# CPU: sample /proc/stat twice, 0.5s apart
read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat
sleep 0.5
read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
idle=$(( (i2 + w2) - (i1 + w1) ))
total=$(( (u2+n2+s2+i2+w2+q2+sq2) - (u1+n1+s1+i1+w1+q1+sq1) ))
cpu=$(( 100 * (total - idle) / total ))

ram=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
state=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
[ "$state" = "Charging" ] && plug="+" || plug=""

echo "CPU ${cpu}%  RAM ${ram}%  BAT ${bat:-N/A}%${plug}"
echo "---"
echo "Uptime: $(uptime -p)"
echo "Load: $(cut -d' ' -f1-3 /proc/loadavg)"
