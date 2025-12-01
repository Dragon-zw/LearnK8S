#!/bin/bash

# 安装 Dapr 1.8.7 并修复 Configuration 问题

echo "步骤 1: 安装 Dapr (会失败,但会创建 CRD)"
helm install dapr dapr/dapr \
  --namespace dapr-system \
  --create-namespace \
  --version 1.8.7 \
  --wait=false \
  2>&1 || true

echo ""
echo "步骤 2: 等待 CRD 创建完成"
sleep 5

echo ""
echo "步骤 3: 删除失败的 release"
helm uninstall dapr --namespace dapr-system 2>&1 || true

echo ""
echo "步骤 4: 删除有问题的 Configuration"
kubectl delete configuration daprsystem -n dapr-system 2>&1 || true

echo "步骤 5: 创建正确的 Configuration(带 Helm 标签)"
cat <<EOF | kubectl apply -f -
apiVersion: dapr.io/v1alpha1
kind: Configuration
metadata:
  name: daprsystem
  namespace: dapr-system
  labels:
    app.kubernetes.io/managed-by: Helm
  annotations:
    meta.helm.sh/release-name: dapr
    meta.helm.sh/release-namespace: dapr-system
spec:
  mtls:
    enabled: true
    workloadCertTTL: 24h
    allowedClockSkew: 15m
    controlPlaneTrustDomain: "cluster.local"
    sentryAddress: "dapr-sentry.dapr-system.svc.cluster.local:80"
EOF

echo ""
echo "步骤 6: 使用 --skip-crds 重新安装 Dapr"
helm install dapr dapr/dapr \
  --namespace dapr-system \
  --version 1.8.7 \
  --skip-crds

echo ""
echo "步骤 7: 验证安装"
kubectl get pods -n dapr-system
