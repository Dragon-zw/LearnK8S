#!/bin/bash

# Linkerd Grafana 集成安装脚本
# 用于在 Linkerd Viz 中部署独立的 Grafana 并加载官方 Dashboard

set -e

echo "=== Linkerd Grafana 集成安装 ==="

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 配置变量
NAMESPACE="linkerd-viz"
GRAFANA_RELEASE="grafana"
DASHBOARDS_DIR="/tmp/linkerd2/grafana/dashboards"

echo -e "${YELLOW}步骤 1: 检查 Linkerd Viz 是否已安装${NC}"
if ! kubectl get namespace $NAMESPACE &>/dev/null; then
    echo -e "${RED}错误: linkerd-viz 命名空间不存在${NC}"
    echo "请先安装 Linkerd Viz: linkerd viz install | kubectl apply -f -"
    exit 1
fi
echo -e "${GREEN}✓ Linkerd Viz 命名空间存在${NC}"

echo -e "${YELLOW}步骤 2: 检查 Dashboard 文件${NC}"
if [ ! -d "$DASHBOARDS_DIR" ]; then
    echo -e "${YELLOW}下载 Linkerd Dashboard 文件...${NC}"
    cd /tmp
    if [ -d "linkerd2" ]; then
        rm -rf linkerd2
    fi
    git clone --depth 1 https://github.com/linkerd/linkerd2.git
fi
echo -e "${GREEN}✓ Dashboard 文件已就绪${NC}"

echo -e "${YELLOW}步骤 3: 创建 Dashboard ConfigMap${NC}"
kubectl create configmap linkerd-grafana-dashboards \
    -n $NAMESPACE \
    --from-file=$DASHBOARDS_DIR \
    --dry-run=client -o yaml | kubectl create -f -
echo -e "${GREEN}✓ Dashboard ConfigMap 已创建${NC}"

echo -e "${YELLOW}步骤 4: 检查 Grafana Helm Chart${NC}"
if ! helm repo list | grep -q "^grafana"; then
    echo "添加 Grafana Helm 仓库..."
    helm repo add grafana https://grafana.github.io/helm-charts
fi
helm repo update
echo -e "${GREEN}✓ Grafana Helm Chart 已就绪${NC}"

echo -e "${YELLOW}步骤 5: 部署 Grafana${NC}"
helm upgrade --install $GRAFANA_RELEASE \
    -n $NAMESPACE \
    grafana/grafana \
    -f values-fixed.yaml \
    --wait
echo -e "${GREEN}✓ Grafana 已部署${NC}"

echo -e "${YELLOW}步骤 6: 等待 Grafana Pod 就绪${NC}"
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=grafana \
    -n $NAMESPACE \
    --timeout=300s
echo -e "${GREEN}✓ Grafana Pod 已就绪${NC}"

echo -e "${YELLOW}步骤 7: 获取 Grafana 访问信息${NC}"
echo ""
echo -e "${GREEN}=== Grafana 安装成功! ===${NC}"
echo ""
echo "访问方式 1 - Port Forward:"
echo "  kubectl port-forward -n $NAMESPACE svc/grafana 3000:80"
echo "  然后访问: http://localhost:3000"
echo ""
echo "访问方式 2 - 创建 Ingress (需要先配置 Ingress Controller)"
echo ""
echo "默认登录信息:"
echo "  用户名: admin"
echo "  密码: (运行以下命令获取)"
echo "  kubectl get secret -n $NAMESPACE grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo"
echo ""
echo "Dashboard 位置: Dashboards -> Browse -> Linkerd 文件夹"
echo ""

echo -e "${YELLOW}步骤 8: 验证 Dashboard 加载${NC}"
sleep 10
POD_NAME=$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}')
echo "检查 Grafana 日志..."
if kubectl logs -n $NAMESPACE $POD_NAME --tail=50 | grep -q "error"; then
    echo -e "${YELLOW}警告: 发现一些错误日志，请检查${NC}"
    kubectl logs -n $NAMESPACE $POD_NAME --tail=20
else
    echo -e "${GREEN}✓ 未发现错误${NC}"
fi

echo ""
echo -e "${GREEN}=== 安装完成! ===${NC}"
