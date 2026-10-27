# 🔒 《吃什么》应用安全配置指南

## 🚨 重要提醒

**本项目包含敏感信息，请务必遵循以下安全配置步骤！**

## 📋 环境配置步骤

### 1. 复制环境配置文件

```bash
cp .env.example .env
```

### 2. 配置API密钥

AI 服务独家使用 MiniMax，且区分两种模式（详见 `EXECUTION_PROXY_API.md`）：

```env
# 本地开发联调（客户端直连 MiniMax）：
MINIMAX_API_KEY=your_real_api_key_here

# 生产构建：客户端不配置任何 AI 密钥，只配置执行代理地址，
# AI 文本调用经代理转发，MiniMax 密钥只留服务端：
# EXECUTION_PROXY_BASE_URL=https://your-proxy-host
# EXECUTION_PROXY_AUTH_TOKEN=your_proxy_token
```

> release 构建即使误注入 `MINIMAX_API_KEY` 也不会使用（AI 按代理模式运行，未配代理则走本地兜底），避免长期密钥随包分发。代理地址必须是 HTTPS。

### 3. 配置本地安全变量

```env
# 本地密码哈希盐值
PASSWORD_SALT=your_random_salt_here

# 仅用于本地离线会话签名，不是远程用户身份
JWT_SECRET=your_jwt_secret_here

# 仅用于迁移旧版 XOR 数据；升级期间保留原值
ENCRYPTION_KEY=your_encryption_key_here
```

新会话数据由系统 Keychain/Keystore 保护，不再使用 `ENCRYPTION_KEY` 加密。已有安装必须保留旧值，直到旧数据完成首次读取迁移；否则旧会话无法解密并会要求重新登录。

### 4. 生成随机字符串的方法

#### 方法1：使用在线工具
- 访问 https://randomkeygen.com/
- 选择 "CodeIgniter Encryption Keys" 或 "Strong Password"

#### 方法2：使用命令行（Mac/Linux）
```bash
# 生成32位随机字符串
openssl rand -base64 32

# 生成64位随机字符串
openssl rand -base64 64
```

#### 方法3：使用Python
```python
import secrets
import string

def generate_key(length=32):
    alphabet = string.ascii_letters + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(length))

print(generate_key(32))  # 生成32位
print(generate_key(64))  # 生成64位
```

## 🔐 生产环境配置

### 1. 禁用调试模式

```env
DEBUG_MODE=false
```

### 2. 使用环境变量

生产客户端**不配置任何 AI、平台或支付密钥**，只配置代理地址：

```bash
export EXECUTION_PROXY_BASE_URL="https://your-proxy-host"
export EXECUTION_PROXY_AUTH_TOKEN="your_proxy_token"
```

MiniMax、美团/饿了么/点评、支付宝商户密钥只配置在对应服务端
（`execution_proxy_server.dart` / 适配器 / `payment_server.dart`），绝不导出给客户端构建。

## 会话存储与令牌边界

- iOS/macOS 使用 Keychain；Android 使用 Keystore 保护的 RSA OAEP + AES-GCM，最低支持 Android 6.0（API 23）。Android 自动备份已关闭，避免密文恢复到没有对应密钥的设备。
- 旧版 `secure_*` / `iv_*` XOR 数据只在读取时迁移；系统安全存储写入成功后才删除旧副本。
- 本地离线 JWT 只用于本机会话校验，不作为执行代理的用户身份。执行代理和 AI 代理只默认发送 `eatwhat_auth_server` 签发的远程会话 JWT。
- Web 安全存储依赖 WebCrypto，只能在 HTTPS 或 localhost 使用；它不能替代 CSP、HSTS 和 XSS 防护。

## 📝 安全检查清单

- [ ] `.env` 文件已添加到 `.gitignore`
- [ ] 本地默认盐与 JWT 密钥已替换；旧安装迁移期间保留原 `ENCRYPTION_KEY`
- [ ] 客户端构建不包含任何 AI/平台/支付密钥（只配置 `EXECUTION_PROXY_BASE_URL`）
- [ ] 生产环境禁用了调试模式
- [ ] 定期轮换敏感密钥
- [ ] 不要在代码中硬编码敏感信息

## 🚨 安全警告

1. **永远不要**提交包含真实API密钥的 `.env` 文件
2. **永远不要**在代码中硬编码敏感信息
3. **定期轮换**API 与服务端密钥；旧数据迁移期间不要轮换 `ENCRYPTION_KEY`
4. **监控**API密钥的使用情况
5. **限制**API密钥的访问权限

## 🔧 故障排除

### 配置验证失败
如果看到 "Configuration validation failed" 错误：
1. 检查 `.env` 文件是否存在
2. 确认 `MINIMAX_API_KEY` 与 `EXECUTION_PROXY_BASE_URL` 至少配置其一（本地直连或代理模式）
3. 确保API密钥不是占位符值

### API密钥验证失败
如果看到 "API key security validation failed" 错误：
1. 确保API密钥不是 "your_api_key_here"
2. 检查API密钥长度是否足够（至少20个字符）
3. 验证API密钥是否有效

## 📞 支持

如果在配置过程中遇到问题，请检查：
1. 日志输出中的具体错误信息
2. 环境变量是否正确设置
3. API密钥是否有效且有足够权限