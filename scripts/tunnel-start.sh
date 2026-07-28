#!/bin/bash
LOG="/tmp/darak-tunnel.log"
URL_FILE="/Users/mac/Desktop/darak-invest-backend/tunnel-url.txt"

echo "$(date): Starting tunnel..." >> "$LOG"

cloudflared tunnel --url http://localhost:5000 2>&1 | while read line; do
  echo "$line" >> "$LOG"
  if echo "$line" | grep -q "trycloudflare.com"; then
    URL=$(echo "$line" | grep -oP 'https://[a-zA-Z0-9-]+\.trycloudflare\.com')
    if [ -n "$URL" ]; then
      echo "$URL" > "$URL_FILE"
      echo "$(date): URL saved: $URL" >> "$LOG"
    fi
  fi
done
