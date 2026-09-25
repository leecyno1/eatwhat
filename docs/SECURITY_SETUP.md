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

### 3. 生成安全密钥

**重要：请生成随机字符串替换以下默认值**

```bash
# 生成密码哈希盐值（建议32位随机字符串）
PASSWORD_SALT=your_random_salt_here

# 生成JWT密钥（建议64位随机字符串）  
JWT_SECRET=your_jwt_secret_here

# 生成加密密钥（建议32位随机字符串）
ENCRYPTION_KEY=your_encryption_key_here
```

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

## 📝 安全检查清单

- [ ] `.env` 文件已添加到 `.gitignore`
- [ ] 所有默认密钥已替换为随机生成的值
- [ ] 客户端构建不包含任何 AI/平台/支付密钥（只配置 `EXECUTION_PROXY_BASE_URL`）
- [ ] 生产环境禁用了调试模式
- [ ] 定期轮换敏感密钥
- [ ] 不要在代码中硬编码敏感信息

## 🚨 安全警告

1. **永远不要**提交包含真实API密钥的 `.env` 文件
2. **永远不要**在代码中硬编码敏感信息
3. **定期轮换**API密钥和加密密钥
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