#!/bin/bash
MESSAGE="$1"

# Для Telegram (через bot и chat_id)
curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d "chat_id=${TELEGRAM_CHAT_ID}&text=${MESSAGE}"

# Или для email (через mailx)
echo "$MESSAGE" | mailx -s "CI Alert" stds58@gmail.com