#!/bin/bash

export HOME=/home/student
export PATH=/usr/local/bin:/usr/bin:/bin
export KUBECONFIG=/home/student/.kube/config

REGION="ap-northeast-2"
NAMESPACE="OnPrem/Kubernetes"
METRIC_NAME="Heartbeat"
CLUSTER_NAME="onprem-k8s"

# Kubernetes API 상태 확인
if kubectl get --raw='/readyz' >/dev/null 2>&1; then
    HEARTBEAT=1
    STATUS="Kubernetes 정상"
else
    HEARTBEAT=0
    STATUS="Kubernetes 비정상"
fi

# CloudWatch에 Heartbeat 전송
aws cloudwatch put-metric-data \
    --namespace "$NAMESPACE" \
    --metric-name "$METRIC_NAME" \
    --dimensions Cluster="$CLUSTER_NAME" \
    --unit Count \
    --value "$HEARTBEAT" \
    --storage-resolution 60 \
    --region "$REGION"

# 확인용 출력
echo "$(date '+%Y-%m-%d %H:%M:%S') - $STATUS - Heartbeat=$HEARTBEAT"
