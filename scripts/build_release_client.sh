#!/usr/bin/env bash
# 生产客户端构建：必须把代理/认证地址编译进 App。
# 客户端不包含任何平台密钥；美团 AppSecret 只在服务端。
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PROXY_BASE_URL="${EXECUTION_PROXY_BASE_URL:-https://eatwhat.monkeykingfury.com/eatwhat}"
AUTH_BASE_URL="${EATWHAT_AUTH_BASE_URL:-https://eatwhat.monkeykingfury.com}"
TARGET="${1:-apk}"
shift || true

case "$TARGET" in
  apk)
    flutter build apk --release --split-per-abi \
      --dart-define="EXECUTION_PROXY_BASE_URL=$PROXY_BASE_URL" \
      --dart-define="EATWHAT_AUTH_BASE_URL=$AUTH_BASE_URL" "$@"
    ;;
  aab)
    flutter build appbundle --release \
      --dart-define="EXECUTION_PROXY_BASE_URL=$PROXY_BASE_URL" \
      --dart-define="EATWHAT_AUTH_BASE_URL=$AUTH_BASE_URL" "$@"
    ;;
  ios)
    flutter build ios --release --no-codesign \
      --dart-define="EXECUTION_PROXY_BASE_URL=$PROXY_BASE_URL" \
      --dart-define="EATWHAT_AUTH_BASE_URL=$AUTH_BASE_URL" "$@"
    ;;
  *)
    echo "usage: $0 [apk|aab|ios] [extra flutter build args...]" >&2
    exit 2
    ;;
esac
