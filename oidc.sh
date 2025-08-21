#!/bin/bash
set -euo pipefail

# --- 설정 ---
ROLE_ARN="${1:?Usage: $0 <ROLE_ARN>}"
STS_ENDPOINT="${2:-https://sts.samsungspc.com}"

# OIDC 토큰 요청
ID_TOKEN=$(curl -sSL -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
  "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=sts.samsungspc.com" | jq -r '.value')

if [ -z "$ID_TOKEN" ] || [ "$ID_TOKEN" == "null" ]; then
  echo "Error: OIDC token could not be fetched." >&2
  exit 1
fi

# 🔍 토큰 디코딩 확인 (선택)
echo "===== OIDC Token Claims ====="
echo "$ID_TOKEN" | cut -d "." -f2 | base64 --decode | jq .
echo "============================="

# STS Assume Role
RESPONSE=$(aws sts assume-role-with-web-identity \
  --role-arn "$ROLE_ARN" \
  --role-session-name "GitHubActionsSession" \
  --web-identity-token "$ID_TOKEN" \
  --endpoint-url "$STS_ENDPOINT" \
  --output json)

ACCESS_KEY=$(echo "$RESPONSE" | jq -r '.Credentials.AccessKeyId')
SECRET_KEY=$(echo "$RESPONSE" | jq -r '.Credentials.SecretAccessKey')
SESSION_TOKEN=$(echo "$RESPONSE" | jq -r '.Credentials.SessionToken')

# GitHub Actions 환경 변수 등록
echo "AWS_ACCESS_KEY_ID=$ACCESS_KEY" >> $GITHUB_ENV
echo "AWS_SECRET_ACCESS_KEY=$SECRET_KEY" >> $GITHUB_ENV
echo "AWS_SESSION_TOKEN=$SESSION_TOKEN" >> $GITHUB_ENV

echo "✅ SPC OIDC 로그인 완료"
