#!/usr/bin/env bash
notify-send "SCRIPT_RAN" "The script executed" -u critical
touch /tmp/__script_ran
