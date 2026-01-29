#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:3000}"
EMAIL="${EMAIL:-user_$(date +%s)@example.com}"
PASSWORD="${PASSWORD:-secret123}"

say() {
  printf "\n==> %s\n" "$1"
}

say "Register user"
register_response=$(curl -sS -X POST "$BASE_URL/api/v1/register" \
  -H "Content-Type: application/json" \
  -d "{\"user\":{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"password_confirmation\":\"$PASSWORD\"}}")

printf "%s\n" "$register_response"

user_id=$(printf "%s" "$register_response" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["id"]')

say "List users"
curl -sS "$BASE_URL/api/v1/users" | ruby -rjson -e 'puts JSON.pretty_generate(JSON.parse(STDIN.read))'

say "Update user email"
new_email="updated_${EMAIL}"
curl -sS -X PATCH "$BASE_URL/api/v1/users/$user_id" \
  -H "Content-Type: application/json" \
  -d "{\"user\":{\"email\":\"$new_email\"}}" | ruby -rjson -e 'puts JSON.pretty_generate(JSON.parse(STDIN.read))'

echo
say "Done"
