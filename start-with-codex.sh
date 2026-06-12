#!/bin/bash

# DeepWiki with Codex 自定义模型启动脚本

echo "=========================================="
echo "  DeepWiki with Codex Custom Models"
echo "=========================================="
echo ""

# 检查环境变量
if [ -z "$CODEX_BASE_URL" ]; then
    echo "⚠️  警告: CODEX_BASE_URL 未设置"
    echo "   请设置: export CODEX_BASE_URL=https://your-codex-endpoint.com/v1"
    echo ""
fi

if [ -z "$CODEX_API_KEY" ]; then
    echo "⚠️  警告: CODEX_API_KEY 未设置"
    echo "   请设置: export CODEX_API_KEY=your_api_key"
    echo ""
fi

# 选择配置文件
echo "选择启动模式:"
echo "1) 使用 LiteLLM 网关（推荐，支持 Codex）"
echo "2) 标准模式（原生支持的供应商）"
read -p "请选择 [1/2]: " choice

case $choice in
    1)
        echo ""
        echo "🚀 使用 LiteLLM 网关启动..."

        # 检查是否有自定义配置
        if [ -f "litellm-config-codex.yml" ]; then
            echo "   使用 litellm-config-codex.yml"
            # 临时备份原配置
            if [ -f "litellm-config.yml" ]; then
                cp litellm-config.yml litellm-config.yml.bak
            fi
            cp litellm-config-codex.yml litellm-config.yml
        fi

        # 停止旧容器
        docker compose down 2>/dev/null

        # 启动 LiteLLM 版本
        docker compose -f docker-compose-litellm.yml up -d

        echo ""
        echo "✅ DeepWiki with LiteLLM 启动中..."
        echo ""
        echo "服务地址:"
        echo "  - DeepWiki 前端: http://localhost:3000"
        echo "  - DeepWiki API:  http://localhost:8001"
        echo "  - LiteLLM 网关:  http://localhost:4000"
        echo ""
        echo "查看日志: docker compose -f docker-compose-litellm.yml logs -f"
        ;;
    2)
        echo ""
        echo "🚀 使用标准模式启动..."

        # 停止旧容器
        docker compose -f docker-compose-litellm.yml down 2>/dev/null

        # 启动标准版本
        docker compose up -d

        echo ""
        echo "✅ DeepWiki 启动中..."
        echo ""
        echo "服务地址:"
        echo "  - DeepWiki 前端: http://localhost:3000"
        echo "  - DeepWiki API:  http://localhost:8001"
        echo ""
        echo "查看日志: docker compose logs -f"
        ;;
    *)
        echo "无效选择"
        exit 1
        ;;
esac

echo ""
echo "等待服务启动..."
sleep 5

# 检查服务状态
echo ""
echo "检查服务状态..."
docker compose ps 2>/dev/null || docker compose -f docker-compose-litellm.yml ps

echo ""
echo "=========================================="
echo "🎉 启动完成！"
echo "=========================================="
