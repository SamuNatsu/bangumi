#!/bin/bash

# Constants
UPYUN_RND_CHARSET="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

# (str, flag:no-cleanup) -> !
fail() {
  if [ -n "$ACCESS_TOKEN" ] && [[ "$2" != "--no-cleanup" ]]; then
    del_access_token
  fi

  echo "error: $1" >&2
  exit 1
}

# (str, len) -> str
mask_str() {
  local STR_LEN=${#1}
  local UNMASK_LEN="$2"
  local MASK_LEN=$(( STR_LEN - UNMASK_LEN ))
  local PREFIX="${1:0:UNMASK_LEN}"

  printf -v STARS '%*s' "$MASK_LEN" ''
  STARS="${STARS// /*}"

  echo "$PREFIX$STARS"
  unset STARS
}

# (charset, len, prefix?) -> str
gen_rnd_str() {
  local RND=local RND=$(LC_ALL=C tr -dc "$1" </dev/urandom 2>/dev/null | head -c "$2")

  if [ -z "$3" ]; then
    echo "$RND"
  else
    echo "$3$RND"
  fi
}

# (username, passwd) -> ()
get_access_token() {
  local CODE=$(gen_rnd_str "$UPYUN_RND_CHARSET" 32)
  local NAME=$(gen_rnd_str "$UPYUN_RND_CHARSET" 8 "deploy-")
  local TIMESTAMP_NOW=$(date +%s)
  local EXPIRED_AT=$(( TIMESTAMP_NOW + 120 ))

  local REQ=$(
    jq -n \
      --arg user "$1" \
      --arg pass "$2" \
      --arg code "$CODE" \
      --arg name "$NAME" \
      --arg exp "$EXPIRED_AT" \
      '{"username":$user,"password":$pass,"code":$code,"name":$name,"scope":"global","expired_at":$exp}'
  )
  local RESP=$(
    curl -s \
      -H "Content-Type: application/json" \
      -d "$REQ" \
      https://api.upyun.com/oauth/tokens
  )

  local IS_ERROR=$(echo "$RESP" | jq -r '.error_code != null')
  if [[ "$IS_ERROR" == "true" ]]; then
    local CODE=$(echo "$RESP" | jq -r '.error_code')
    local MESSAGE=$(echo "$RESP" | jq -r '.message')
    fail "fail to get access token: $MESSAGE ($CODE)"
  fi

  ACCESS_TOKEN=$(echo "$RESP" | jq -r '.access_token')
  TOKEN_NAME="$NAME"

  local MASK_TOKEN=$(mask_str "$ACCESS_TOKEN" 5)
  echo "access token: $MASK_TOKEN"
  echo "token name: $TOKEN_NAME"
  echo "nonce: $CODE"
}

# () -> ()
del_access_token() {
  local RESP=$(
    curl -s \
      -X DELETE \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      "https://api.upyun.com/oauth/tokens?name=$TOKEN_NAME"
  )

  local IS_ERROR=$(echo "$RESP" | jq -r '.error_code != null')
  if [[ "$IS_ERROR" == "true" ]]; then
    local CODE=$(echo "$RESP" | jq -r '.error_code')
    local MESSAGE=$(echo "$RESP" | jq -r '.message')
    fail "fail to delete access token: $MESSAGE ($CODE)" --no-cleanup
  fi

  echo "access token deleted"
}

# (...url) -> ()
refresh() {
  local URLS=$(printf "%s\n" "$@")

  local REQ=$(
    jq -n \
      --arg urls "$URLS" \
      '{"noif":0,"delay":0,"source_url":$urls}'
  )
  local RESP=$(
    curl -s \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$REQ" \
      https://api.upyun.com/buckets/purge/batch
  )

  if [[ "$RESP" =~ ^\[ ]]; then
    echo "$RESP"
    echo "cache refreshed"
  else
    local CODE=$(echo "$RESP" | jq -r '.error_code')
    local MESSAGE=$(echo "$RESP" | jq -r '.message')
    fail "fail to refresh cache: $MESSAGE ($CODE)"
  fi
}

# (username, password) -> ()
main() {
  if [ -z "$1" ]; then
    fail "username cannot be empty"
  fi
  if [ -z "$2" ]; then
    fail "password cannot be empty"
  fi

  get_access_token $1 $2
  refresh \
    "https://bangumi.rainiar.top" \
    "https://bangumi.rainiar.top/about" \
    "https://bangumi.rainiar.top/archives" \
    "https://bangumi.rainiar.top/categories/*" \
    "https://bangumi.rainiar.top/posts/*"
  del_access_token
}

# Main entry
main "$@"
