# 接入自定义模型供应商（如 Codex）到 DeepWiki

DeepWiki 通过 LiteLLM 网关支持接入任何自定义模型供应商。

## 方法 1：使用 LiteLLM 网关（推荐）

### 步骤 1：配置 LiteLLM 网关

编辑 `litellm-config.yml`，添加你的自定义模型：

```yaml
model_list:
  # 你的自定义 Codex 模型
  - model_name: codex-claude-sonnet
    litellm_params:
      model: openai/claude-sonnet-4-6  # 使用 openai/ 前缀表示 OpenAI 兼容 API
      api_base: https://your-codex-endpoint.com/v1  # 你的 Codex API 端点
      api_key: ${CODEX_API_KEY}  # 从环境变量读取

  - model_name: codex-gpt-4o
    litellm_params:
      model: openai/gpt-4o
      api_base: https://your-codex-endpoint.com/v1
      api_key: ${CODEX_API_KEY}

  # 添加更多模型...

general_settings:
  database_url: postgres://litellm:litellm_password@db:5432/litellm

litellm_settings:
  set_verbose: true
  drop_params: true  # 忽略不支持的参数
```

### 步骤 2：设置环境变量

编辑 `docker-compose-litellm.env`：

```bash
# LiteLLM 配置
LITELLM_BASE_URL=http://litellm:4000
LITELLM_API_KEY=sk-1234
LITELLM_MASTER_KEY=sk-1234

# 你的 Codex API Key
CODEX_API_KEY=your_codex_api_key_here

# 可选：如果还需要其他供应商
GOOGLE_API_KEY=your_google_key
OPENAI_API_KEY=your_openai_key
```

### 步骤 3：更新 generator.json（已完成）

`api/config/generator.json` 中已经添加了 `litellm` 供应商配置：

```json
{
  "default_provider": "litellm",  // 可以改为 litellm
  "providers": {
    "litellm": {
      "client_class": "LiteLLMClient",
      "default_model": "codex-claude-sonnet",  // 使用你配置的模型名
      "supportsCustomModel": true,
      "models": {
        "codex-claude-sonnet": {
          "temperature": 0.7,
          "top_p": 0.8
        },
        "codex-gpt-4o": {
          "temperature": 0.7,
          "top_p": 0.8
        }
      }
    }
  }
}
```

### 步骤 4：启动 DeepWiki with LiteLLM

```bash
# 停止当前运行的实例
docker compose down

# 使用 LiteLLM 配置启动
docker compose -f docker-compose-litellm.yml up -d
```

这将启动：
- PostgreSQL 数据库（用于 LiteLLM）
- LiteLLM 网关（端口 4000）
- DeepWiki（端口 3000 和 8001）

### 步骤 5：验证配置

1. 访问 LiteLLM 管理界面：http://localhost:4000
2. 访问 DeepWiki：http://localhost:3000
3. 在前端选择 "LiteLLM" 作为模型供应商
4. 选择你配置的模型（如 `codex-claude-sonnet`）

## 方法 2：直接添加自定义客户端

如果你不想使用 LiteLLM 网关，可以直接创建一个自定义客户端。

### 步骤 1：创建自定义客户端

创建 `api/codex_client.py`：

```python
import os
from typing import Optional, Callable
from openai import AsyncOpenAI, OpenAI
from api.openai_client import OpenAIClient

class CodexClient(OpenAIClient):
    """
    Codex 自定义客户端（OpenAI 兼容）
    """
    
    def __init__(
        self,
        api_key: Optional[str] = None,
        chat_completion_parser: Optional[Callable] = None,
        input_type: str = "text",
        base_url: Optional[str] = None,
        env_base_url_name: str = "CODEX_BASE_URL",
        env_api_key_name: str = "CODEX_API_KEY",
    ):
        resolved_base_url = base_url or os.getenv(
            env_base_url_name, 
            "https://your-codex-endpoint.com/v1"
        )
        super().__init__(
            api_key=api_key,
            chat_completion_parser=chat_completion_parser,
            input_type=input_type,
            base_url=resolved_base_url,
            env_base_url_name=env_base_url_name,
            env_api_key_name=env_api_key_name,
        )
```

### 步骤 2：注册客户端

编辑 `api/config.py`，添加：

```python
from api.codex_client import CodexClient

# 在 CLIENT_REGISTRY 中添加
CLIENT_REGISTRY = {
    "OpenAIClient": OpenAIClient,
    "CodexClient": CodexClient,
    # ... 其他客户端
}
```

### 步骤 3：配置 generator.json

```json
{
  "providers": {
    "codex": {
      "client_class": "CodexClient",
      "default_model": "claude-sonnet-4-6",
      "supportsCustomModel": true,
      "models": {
        "claude-sonnet-4-6": {
          "temperature": 0.7,
          "top_p": 0.8
        }
      }
    }
  }
}
```

### 步骤 4：设置环境变量

在 `.env` 中添加：

```bash
CODEX_BASE_URL=https://your-codex-endpoint.com/v1
CODEX_API_KEY=your_codex_api_key
```

## 推荐方案

**使用 LiteLLM 网关（方法 1）**，因为：

✅ 无需修改 DeepWiki 代码  
✅ 支持动态添加/删除模型  
✅ 统一的负载均衡和监控  
✅ 支持任何 OpenAI 兼容的 API  
✅ 可以同时接入多个供应商  

## 常见问题

**Q: 我的 API 端点不是 OpenAI 兼容的怎么办？**  
A: LiteLLM 支持 100+ 种不同的 API 格式，查看文档：https://docs.litellm.ai/docs/providers

**Q: 如何在前端选择自定义模型？**  
A: 在生成 Wiki 时，前端会显示所有配置的供应商和模型，直接选择即可。

**Q: 可以同时使用多个供应商吗？**  
A: 可以！在 `generator.json` 中配置多个 provider，前端可以切换。

**Q: LiteLLM 网关会影响性能吗？**  
A: 影响很小（<50ms），而且可以通过 LiteLLM 获得缓存、重试等增强功能。

## 下一步

配置完成后：
1. 重启 DeepWiki：`docker compose -f docker-compose-litellm.yml restart`
2. 访问 http://localhost:3000
3. 输入仓库 URL，选择你的自定义模型
4. 开始生成 Wiki！
