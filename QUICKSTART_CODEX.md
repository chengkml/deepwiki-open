# 🚀 快速配置 DeepWiki 使用 Codex 自定义模型

## 一键配置步骤

### 1. 设置 Codex 环境变量

```bash
# 方式 A：临时设置（当前终端会话）
export CODEX_BASE_URL="https://your-codex-endpoint.com/v1"
export CODEX_API_KEY="your_codex_api_key"

# 方式 B：永久设置（添加到 .env 文件）
cp .env.codex.example .env
# 然后编辑 .env 文件，填入你的实际配置
```

### 2. 配置 LiteLLM（将 Codex 模型路由到 DeepWiki）

编辑 `litellm-config-codex.yml`，修改模型名称和端点：

```yaml
model_list:
  - model_name: codex-claude-sonnet    # 在 DeepWiki 中显示的名称
    litellm_params:
      model: openai/claude-sonnet-4-6   # 实际调用的模型
      api_base: ${CODEX_BASE_URL}
      api_key: ${CODEX_API_KEY}
```

### 3. 启动 DeepWiki

```bash
# 使用自动化脚本启动
./start-with-codex.sh

# 或手动启动
docker compose -f docker-compose-litellm.yml up -d
```

### 4. 访问 DeepWiki

打开浏览器访问 http://localhost:3000

在前端界面中：
1. 选择 **LiteLLM** 作为模型供应商
2. 选择你配置的模型（如 `codex-claude-sonnet`）
3. 输入仓库 URL，开始生成 Wiki

## 架构说明

```
用户请求 → DeepWiki Frontend (3000)
              ↓
         DeepWiki API (8001)
              ↓
         LiteLLM Gateway (4000)
              ↓
         Codex API Endpoint
```

**为什么使用 LiteLLM？**

- ✅ 统一接口：支持 100+ 种模型供应商
- ✅ 负载均衡：自动分配请求到多个端点
- ✅ 缓存和重试：提高稳定性
- ✅ 成本追踪：监控 API 使用情况
- ✅ 无需修改 DeepWiki 代码

## 当前配置状态

✅ **已完成的配置：**

1. ✅ 在 `api/config/generator.json` 中添加了 `litellm` 供应商
2. ✅ 设置 `litellm` 为默认供应商
3. ✅ 创建了 `litellm-config-codex.yml` 配置文件
4. ✅ 创建了 `.env.codex.example` 环境变量模板
5. ✅ 创建了 `start-with-codex.sh` 启动脚本

⏳ **你需要做的：**

1. ⏳ 填写 Codex API 端点和密钥
2. ⏳ 运行启动脚本

## 常见配置

### 配置 1：仅使用 Codex 模型

```yaml
# litellm-config-codex.yml
model_list:
  - model_name: codex-main
    litellm_params:
      model: openai/your-model-name
      api_base: ${CODEX_BASE_URL}
      api_key: ${CODEX_API_KEY}
```

### 配置 2：混合使用 Codex + 其他供应商

```yaml
model_list:
  # Codex 模型（主力）
  - model_name: codex-claude
    litellm_params:
      model: openai/claude-sonnet-4-6
      api_base: ${CODEX_BASE_URL}
      api_key: ${CODEX_API_KEY}

  # 备用：本地 Ollama
  - model_name: local-llama
    litellm_params:
      model: ollama/llama3:8b
      api_base: http://host.docker.internal:11434
      api_key: not-needed
```

### 配置 3：多个 Codex 端点负载均衡

```yaml
model_list:
  - model_name: codex-balanced
    litellm_params:
      model: openai/claude-sonnet-4-6
      api_base: https://codex-endpoint-1.com/v1
      api_key: ${CODEX_API_KEY_1}

  - model_name: codex-balanced
    litellm_params:
      model: openai/claude-sonnet-4-6
      api_base: https://codex-endpoint-2.com/v1
      api_key: ${CODEX_API_KEY_2}
```

## 验证配置

### 检查 LiteLLM 状态

```bash
# 查看 LiteLLM 日志
docker compose -f docker-compose-litellm.yml logs litellm

# 测试 LiteLLM 端点
curl http://localhost:4000/health
```

### 检查 DeepWiki 状态

```bash
# 查看 DeepWiki 日志
docker compose -f docker-compose-litellm.yml logs deepwiki

# 测试 DeepWiki API
curl http://localhost:8001/health
```

### 测试模型调用

```bash
# 通过 LiteLLM 测试 Codex 模型
curl -X POST http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer sk-1234" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "codex-claude-sonnet",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

## 故障排查

### 问题 1：LiteLLM 无法连接到 Codex

**检查：**
```bash
# 验证环境变量
docker compose -f docker-compose-litellm.yml exec litellm env | grep CODEX

# 测试 Codex 端点可达性
curl -I $CODEX_BASE_URL
```

### 问题 2：DeepWiki 无法连接到 LiteLLM

**检查：**
```bash
# 验证 LiteLLM 运行状态
docker compose -f docker-compose-litellm.yml ps litellm

# 查看网络连接
docker compose -f docker-compose-litellm.yml exec deepwiki ping -c 3 litellm
```

### 问题 3：模型未显示在前端

**解决：**
1. 确保 `api/config/generator.json` 中 `litellm` 配置正确
2. 重启 DeepWiki：`docker compose -f docker-compose-litellm.yml restart deepwiki`
3. 清除浏览器缓存

## 高级配置

### 设置请求超时

```yaml
# litellm-config-codex.yml
litellm_settings:
  request_timeout: 600  # 10 分钟
```

### 启用请求缓存

```yaml
litellm_settings:
  cache: true
  cache_params:
    type: "redis"
    host: "redis"
    port: 6379
```

### 配置速率限制

```yaml
litellm_settings:
  rpm: 100  # 每分钟最多 100 个请求
  tpm: 50000  # 每分钟最多 50k tokens
```

## 参考文档

- [LiteLLM 官方文档](https://docs.litellm.ai/)
- [DeepWiki 完整配置指南](./CUSTOM_MODEL_SETUP.md)
- [Docker Compose 文档](https://docs.docker.com/compose/)

## 需要帮助？

如果遇到问题，请提供以下信息：

1. 你的配置文件（隐藏敏感信息）
2. 错误日志：`docker compose -f docker-compose-litellm.yml logs`
3. 你的使用场景描述
