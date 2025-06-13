Velero Install and Setup

# Options:
## Setup a Minio server (or other object storage)
## Setup Using NFS Storage Class 

# Installing the NFS CSI	
## App Store Install
Add Repo

*nfs-csi-driver-repo.yaml*
```yaml
apiVersion: catalog.cattle.io/v1
kind: ClusterRepo
metadata:
  name: nfs-csi-driver
spec:
  clientSecret: null
  url: >-
    https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
```

```shell
kubectl apply -f nfs-csi-driver-repo.yaml
```

Install through UI and helm values found below.

## Helm install:
### nfs-csi-values.yaml:
```
controller:
  replicas: 2
  runOnControlPlane: true
  runOnMaster: true
externalSnapshotter:
  controller:
    replicas: 2
```

### Install driver with helm
```	
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system --version 4.11.0 -f nfs-csi-values.yaml
```

### Setup storage class
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs2
provisioner: nfs.csi.k8s.io
parameters:
  server: 10.0.0.94
  share: /nfs2
reclaimPolicy: Retain
volumeBindingMode: Immediate
allowVolumeExpansion: true
```

### Example PVC
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: testbucket
  namespace: default
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs2
  volumeMode: Filesystem
  volumeName: my-volume
```

# Prereqs
## S3 or NFS CSI or some other CSI that is available to all nodes

Example S3 Secret
```
apiVersion: v1
kind: Secret
metadata:
  name: mcqnap-s3-secret
  namespace: kube-system
type: Opaque
data:
  accessKey: QmFja3Vwczp5Y001TzVzZ2JSOFdGYUlvdThjOQ==
  secretKey: MU9peWFnNDhnbE5kSGNOUzFqS2pXVmdnRjFpS2h4YWk=
```


# Install Velero CLI
```
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
```