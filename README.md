K8S 구조

.
├── anaconda-ks.cfg
├── db
│   ├── backup
│   │   ├── mongodb-data-nfs-pv-backup.yaml
│   │   ├── mongodb-data-nfs-pvc-backup.yaml
│   │   ├── mongodb-data-pv-backup.yaml
│   │   ├── mongodb-logs-nfs-pv-backup.yaml
│   │   ├── mongodb-logs-nfs-pvc-backup.yaml
│   │   ├── mongodb-logs-pv-backup.yaml
│   │   └── mongodb-statefulset-backup.yaml
│   ├── db-quota.yaml
│   ├── mongodb-data-pvc.yaml
│   ├── mongodb-data-pv.yaml
│   ├── mongodb-data.yaml
│   ├── mongodb-log-pvc.yaml
│   ├── mongodb-log-pv.yaml
│   ├── mongo-express.yaml
│   └── old-yaml
│       ├── db-pvc.yaml
│       ├── mongodb-logs-nfs.yaml
│       ├── mongodb-logs-storage.yaml
│       └── mongodb.yaml
├── db-pvc-backup.yaml
├── exports.pre-failback.2026-10-19-092649
├── fastapi.log
├── full-cluster-backup.sh
├── insert_data.py
├── k8s-backup-cronjob
│   └── k8s-backup-cronjob.yaml
├── metallb
│   └── metallb-config.yaml
├── mongodb-clean-restore.yaml
├── mongodb-statefulset.yaml
└── monitoring
    ├── nfs-prometheus-log-collector.yaml
    ├── nfs-prometheus-logs-pvc.yaml
    ├── nfs-prometheus-logs-sc.yaml
    ├── nfs-prometheus-pvc.yaml
    ├── nfs-prometheus-storageclass.yaml
    └── prometheus-storage-values.yaml
