#!/usr/bin/env bash
# 《吃什么》服务端一键部署脚本（Ubuntu 22.04/24.04 + systemd + nginx）
#
# 用法（在服务器上以 root 运行）：
#   1. git clone https://github.com/leecyno1/eatwhat.git /opt/eatwhat-repo
#   2. cp /opt/eatwhat-repo/.env.example /etc/eatwhat/env   # 然后填真实密钥
#   3. bash /opt/eatwhat-repo/scripts/deploy/deploy.sh
#
# 脚本做这些事：
#   - 安装 Dart SDK（若无）
#   - dart pub get + 编译三个服务为原生可执行文件（/opt/eatwhat/bin/）
#   - 安装 systemd 单元并启动（eatwhat-proxy / eatwhat-payment / eatwhat-auth）
#   - 安装 nginx 站点配置（域名占位 YOUR_DOMAIN，改后 nginx -s reload）
#   - 提示 certbot 签发 HTTPS
#
# 唯一需要人工的：/etc/eatwhat/env 里的真实密钥、域名、certbot。

set -euo pipefail

REPO_DIR="${REPO_DIR:-/opt/eatwhat-repo}"
INSTALL_DIR="${INSTALL_DIR:-/opt/eatwhat}"
ENV_FILE="${ENV_FILE:-/etc/eatwhat/env}"
DART_VERSION="${DART_VERSION:-3.8.0}"

log() { echo -e "\033[1;32m[deploy]\033[0m $*"; }
die() { echo -e "\033[1;31m[deploy] 错误：\033[0m $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "请用 root 运行（sudo bash）"
[[ -d "$REPO_DIR" ]] || die "仓库不存在：$REPO_DIR（先 git clone）"
[[ -f "$ENV_FILE" ]] || {
  mkdir -p "$(dirname "$ENV_FILE")"
  cp "$REPO_DIR/.env.example" "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  die "已生成 $ENV_FILE 模板，请填入真实密钥后重新运行本脚本"
}

# ---------- 1. Dart SDK ----------
if ! command -v dart >/dev/null; then
  log "安装 Dart SDK ${DART_VERSION}..."
  apt-get update -qq
  apt-get install -y -qq curl unzip
  curl -fsSL "https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VERSION}/sdk/dartsdk-linux-x64-release.zip" -o /tmp/dart.zip
  unzip -q /tmp/dart.zip -d /usr/lib
  ln -sf "/usr/lib/dart-sdk/bin/dart" /usr/local/bin/dart
fi
dart --version

# ---------- 2. 编译 ----------
log "拉取最新代码并编译三个服务..."
cd "$REPO_DIR"
git pull --ff-only
dart pub get --no-precompile
mkdir -p "$INSTALL_DIR/bin"
for svc in execution_proxy_server payment_server eatwhat_auth_server; do
  log "编译 $svc..."
  dart compile exe -o "$INSTALL_DIR/bin/$svc" "scripts/$svc.dart" 2>/dev/null \
    || dart compile exe -o "$INSTALL_DIR/bin/$svc" "$REPO_DIR/scripts/$svc.dart"
done

# ---------- 3. systemd ----------
log "安装 systemd 单元..."
for unit in eatwhat-proxy eatwhat-payment eatwhat-auth; do
  sed "s#@INSTALL_DIR@#$INSTALL_DIR#g; s#@ENV_FILE@#$ENV_FILE#g" \
    "$REPO_DIR/scripts/deploy/$unit.service" > "/etc/systemd/system/$unit.service"
done
systemctl daemon-reload
systemctl enable --now eatwhat-proxy eatwhat-payment eatwhat-auth

# ---------- 4. nginx ----------
if ! command -v nginx >/dev/null; then
  log "安装 nginx..."
  apt-get install -y -qq nginx
fi
sed "s#YOUR_DOMAIN#你的域名#g" \
  "$REPO_DIR/scripts/deploy/nginx-eatwhat.conf" > /etc/nginx/sites-available/eatwhat
ln -sf /etc/nginx/sites-available/eatwhat /etc/nginx/sites-enabled/eatwhat
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

log "完成。三个服务状态："
systemctl --no-pager status eatwhat-proxy eatwhat-payment eatwhat-auth | head -30 || true
log "下一步："
log "  1. 修改 /etc/nginx/sites-available/eatwhat 里的 YOUR_DOMAIN 为真实域名，然后 nginx -s reload"
log "  2. apt install certbot python3-certbot-nginx && certbot --nginx -d 你的域名"
log "  3. 客户端打包用 --dart-define=EXECUTION_PROXY_BASE_URL=https://你的域名"
