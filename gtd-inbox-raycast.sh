#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title GTD Inbox
# @raycast.mode silent
# @raycast.icon 📥
# @raycast.argument1 { "type": "text", "placeholder": "수집할 내용 입력..." }
# @raycast.packageName GTD Flow

TITLE="$1"

if [ -z "$TITLE" ]; then
  echo "내용을 입력해주세요"
  exit 1
fi

SUPABASE_URL="https://mzklqcgmpchmhuheurgw.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im16a2xxY2dtcGNobWh1aGV1cmd3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NjA1MDgzNSwiZXhwIjoyMDkxNjI2ODM1fQ.e_1jhBfwsn82OdqxLNycR_YSi0Pfo_M6ZNpFpom6MLU"
USER_ID="901c5c1f-504a-435d-b9b1-bc1c64aec37d"

ITEM_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
CREATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

# 특수문자 안전하게 JSON 인코딩
BODY=$(python3 -c "
import json, sys
title = sys.argv[1]
item_id = sys.argv[2]
user_id = sys.argv[3]
created_at = sys.argv[4]
print(json.dumps({
  'id': item_id,
  'user_id': user_id,
  'title': title,
  'type': 'inbox',
  'status': 'active',
  'notes': '',
  'sort_order': 0,
  'postpone_count': 0,
  'is_important': False,
  'created_at': created_at
}))
" "$TITLE" "$ITEM_ID" "$USER_ID" "$CREATED_AT")

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${SUPABASE_URL}/rest/v1/items" \
  -H "apikey: ${SERVICE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$BODY")

if [ "$HTTP_STATUS" = "201" ]; then
  echo "📥 수집됨: ${TITLE}"
else
  echo "❌ 저장 실패 (HTTP ${HTTP_STATUS})"
  exit 1
fi
