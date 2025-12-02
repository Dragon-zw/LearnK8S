#!/bin/bash
# Dapr Metrics 监控验证脚本

echo "========================================="
echo "Dapr Metrics 监控配置验证"
echo "========================================="
echo ""

# 1. 检查 ServiceMonitor
echo "1. 检查 ServiceMonitor 状态:"
kubectl get servicemonitor dapr-calculator-apps -o wide
echo ""

# 2. 检查 Service Endpoints
echo "2. 检查 Service Endpoints:"
kubectl get endpoints -l metrics=dapr
echo ""

# 3. 检查 Pod 状态
echo "3. 检查应用 Pod 状态:"
kubectl get pods -l 'app in (subtract,add,divide,multiply,calculator-front-end)'
echo ""

# 4. 测试 metrics 端点
echo "4. 测试 addapp 的 metrics 端点 (前 10 行):"
kubectl get pod -l app=add -o name | head -1 | xargs -I {} kubectl exec {} -c daprd -- sh -c 'if command -v curl >/dev/null; then curl -s http://localhost:9090/metrics | head -10; else echo "使用 port-forward 测试"; fi' 2>/dev/null || echo "需要使用 port-forward 方式测试"
echo ""

# 5. 查询 Prometheus targets (需要 port-forward)
echo "5. 验证 Prometheus targets:"
echo "   运行以下命令访问 Prometheus UI:"
echo "   kubectl port-forward -n monitoring svc/prometheus-k8s 9090:9090"
echo "   然后访问: http://localhost:9090/targets"
echo "   搜索: dapr-calculator"
echo ""

# 6. 示例 PromQL 查询
echo "6. 示例 Prometheus 查询 (在 Prometheus UI 中执行):"
echo ""
echo "   # 查看所有 Dapr metrics"
echo "   {job=\"default/dapr-calculator-apps/metrics\"}"
echo ""
echo "   # Dapr gRPC 请求计数"
echo "   dapr_grpc_io_client_completed_rpcs"
echo ""
echo "   # Dapr HTTP 服务器请求"
echo "   dapr_http_server_request_count"
echo ""
echo "   # Dapr 组件加载状态"
echo "   dapr_component_loaded"
echo ""
echo "   # 按应用分组的请求速率"
echo "   rate(dapr_grpc_io_client_completed_rpcs[5m])"
echo ""

echo "========================================="
echo "验证完成"
echo "========================================="
