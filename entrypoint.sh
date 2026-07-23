#!/bin/bash

HUGO_DIR="/app/meteors"

# 1. Run initial generation on boot
echo "[Meteor Dashboard] Running initial report generation..."
/app/generate_meteor_reports.sh

echo "[Meteor Dashboard] Building Hugo static site..."
cd "$HUGO_DIR" && hugo

# 2. Add daily cron job (Runs every day at 06:00 AM)
echo "0 6 * * * /app/generate_meteor_reports.sh && cd /app/meteors && hugo" > /var/spool/cron/crontabs/root

# 3. Start cron daemon in background
crond -b -l 2

# 4. Start Nginx in foreground
echo "[Meteor Dashboard] Starting Nginx on port 80..."
exec nginx -g "daemon off;"
