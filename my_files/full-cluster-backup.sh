#!/bin/bash
set -e

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export KUBECONFIG=/etc/kubernetes/admin.conf
[ ! -f "$KUBECONFIG" ] && export KUBECONFIG=/root/.kube/config

BACKUP_DIR="/tmp/k8s-full-dr"
TIMESTAMP=$(date +"%Y%m%d-%H%M")
LATEST_NAME="full-cluster-backup.tar.gz"
DATED_NAME="full-cluster-backup-${TIMESTAMP}.tar.gz"
RELAY_IP="43.202.217.158"

echo "=== [${TIMESTAMP}] 전체 시스템 통합 백업 시작 ==="
rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR/local-yamls" \
         "$BACKUP_DIR/live-manifests" \
         "$BACKUP_DIR/db-data" \
         "$BACKUP_DIR/logs/mongodb" \
         "$BACKUP_DIR/logs/pods" \
         "$BACKUP_DIR/nfs-volumes"

echo "=== [1/5] /root 디렉터리의 원본 YAML 폴더(db, metallb, monitoring 등) 백업 ==="
cp -r /root/db /root/metallb /root/monitoring /root/k8s-backup-cronjob "$BACKUP_DIR/local-yamls/" 2>/dev/null || true
cp /root/*.yaml "$BACKUP_DIR/local-yamls/" 2>/dev/null || true

echo "=== [2/5] 클러스터 실시간 리소스(StorageClass, PV, PVC, Quota 포함) 추출 ==="
kubectl get sc,pv -o yaml > "$BACKUP_DIR/live-manifests/cluster-storage.yaml" 2>/dev/null || true
NAMESPACES=$(kubectl get ns -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -vE '^(kube-|default|local-path)')

for ns in $NAMESPACES; do
  mkdir -p "$BACKUP_DIR/live-manifests/$ns"
  kubectl get all,cm,secret,ing,pvc,resourcequota -n "$ns" -o yaml \
    | sed '/resourceVersion:/d; /uid:/d; /creationTimestamp:/d; /selfLink:/d; /clusterIP:/d; /clusterIPs:/d; /- 10\./d' \
    > "$BACKUP_DIR/live-manifests/$ns/all-resources.yaml"
done

echo "=== [3/5] MongoDB 데이터(mongodump) 및 실제 로그 파일(/var/log/mongodb) 추출 ==="
# 1) DB 논리 덤프 (테라폼 복구 시 깨짐 방지용)
kubectl exec -n db mongodb-0 -c mongodb -- sh -c "mongodump -u root -p password123 --authenticationDatabase admin --archive" > "$BACKUP_DIR/db-data/mongodb.archive" 2>/dev/null || true
# 2) 파드 내 실제 로그 폴더(/var/log/mongodb) 통째로 복사
kubectl cp db/mongodb-0:/var/log/mongodb "$BACKUP_DIR/logs/mongodb" -c mongodb 2>/dev/null || true

echo "=== [4/5] 클러스터 내 주요 파드(db, monitoring 등) 콘솔 로그 및 NFS 실제 경로 백업 ==="
for ns in $NAMESPACES; do
  for pod in $(kubectl get pods -n "$ns" -o jsonpath='{.items[*].metadata.name}'); do
    kubectl logs -n "$ns" "$pod" --all-containers=true --tail=5000 > "$BACKUP_DIR/logs/pods/${ns}_${pod}.log" 2>/dev/null || true
  done
done

# PV에 등록된 로컬/NFS 경로가 마스터 노드에 존재할 경우 실제 파일(Data+Log) 직접 복사
for path in $(kubectl get pv -o jsonpath='{.items[*].spec.nfs.path} {.items[*].spec.hostPath.path}'); do
  if [ -d "$path" ]; then
     DEST_NAME=$(echo "$path" | sed 's/\//_/g')
     cp -r "$path" "$BACKUP_DIR/nfs-volumes/$DEST_NAME" 2>/dev/null || true
  fi
done

echo "=== [5/5] 전체 압축 및 S3 업로드 ==="
tar -zcf "/tmp/$LATEST_NAME" -C "$BACKUP_DIR" .

upload_to_s3() {
  local TARGET_FILENAME=$1
  UPLOAD_URL=$(curl -s "http://$RELAY_IP:8000/presigned/upload?filename=$TARGET_FILENAME" | python3 -c "import sys, json; print(json.load(sys.stdin)['upload_url'])")
  curl -s -X PUT --upload-file "/tmp/$LATEST_NAME" "$UPLOAD_URL"
}

upload_to_s3 "$LATEST_NAME"
upload_to_s3 "$DATED_NAME"

rm -rf "$BACKUP_DIR" "/tmp/$LATEST_NAME"
echo "✅ [${TIMESTAMP}] 전체 YAML + DB 데이터 + 모든 로그 파일 S3 백업 완료!"
