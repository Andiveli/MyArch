#!/usr/bin/env bash
# Top 3 by CPU and by RAM for overview. Excludes shell/poll noise (ps, upower, …).
# CPU: pidstat 1s average when available (closer to btop); else ps pcpu with filters.
# RAM: aggregate RSS per comm vs MemTotal (like %MEM, without counting poll tools).

set -eu

SKIP='^(ps|bash|sh|sort|head|awk|sleep|pidstat|cat|printf|upower|tee|grep|cut|tr)$'

cpu_top() {
  if command -v pidstat >/dev/null 2>&1; then
    pidstat -u 1 1 2>/dev/null | awk -v skip="$SKIP" '
      /^[0-9]/ && NF >= 9 {
        cmd = $NF
        sub(/\[.*\]/, "", cmd)
        cpu = $8 + 0
        if (cmd ~ skip || cpu <= 0.05) next
        printf "%s|%.1f|0\n", cmd, cpu
      }' | sort -t'|' -k2,2nr | head -3
    return
  fi
  ps -eo comm,pcpu --no-headers 2>/dev/null | awk -v skip="$SKIP" '
    {
      c = $1
      cpu = $2 + 0
      if (c ~ skip || cpu <= 0.1) next
      printf "%s|%.1f|0\n", c, cpu
    }' | sort -t'|' -k2,2nr | head -3
}

mem_top() {
  local total_kb
  total_kb=$(awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null)
  [[ -z "$total_kb" || "$total_kb" -le 0 ]] && return
  ps -eo comm,rss --no-headers 2>/dev/null | awk -v total="$total_kb" -v skip="$SKIP" '
    {
      c = $1
      rss = $2 + 0
      if (c ~ skip || rss <= 0) next
      agg[c] += rss
    }
    END {
      for (c in agg) {
        pct = agg[c] / total * 100
        if (pct < 0.05) continue
        printf "%s|0|%.1f\n", c, pct
      }
    }' | sort -t'|' -k3,3nr | head -3
}

echo '---CPU---'
cpu_top
echo '---MEM---'
mem_top