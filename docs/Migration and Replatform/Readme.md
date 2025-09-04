# Prerequisites

* [krew Installation and Plugins](..\Tools\Krew.md)
  
  * Install all recommended krew plugins
  
* NFS filesystem shared to all nodes in the Source and Destination clusters

* kubeconfig files for both the Source and Destination clusters

* Perform PV/PVC Migrations **BEFORE** installing app yamls to insure the apps can mount the populated PV's

# Install NFS CSI Driver and Create a StorageClass

## Create Repo

### Option 1 - Create ClusterRepo from yaml (on source and destination)

#### nfs-csi-repo.yaml

```yaml
apiVersion: catalog.cattle.io/v1
kind: ClusterRepo
metadata:
  name: nfs-csi
spec:
  url: >-
    https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
```

```sh
kubectl apply -f nfs-csi-repo.yaml
```

### Option 2 - Create ClusterRepo in Rancher UI

#### Apps -> Repositories -> Create

![Insert Screenshot](./images/media/add_nfs_csi_repo1.png)

#### Populate data

* Name
* Description (Optional)
* Index URL = https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts

![Insert Screenshot](./images/media/add_nfs_csi_repo2.png)

## Creatae NFS Storage Class

### Option 1 - Create StorageClass from yaml (on source and destination)

#### example nfs-storageclass.yaml

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage-class
allowVolumeExpansion: false
parameters:
  server: 10.0.0.94
  share: /nfs2
provisioner: nfs.csi.k8s.io
reclaimPolicy: Retain
volumeBindingMode: Immediate
```

### Option 2 - Create StorageClass from Rancher UI

#### Storage -> StorageClasses -> Create

![Insert Screenshot](./images/media/add_storageclass1.png)

#### Populate data

* Name
* Description
* Provisioner = NFS(CSI)
* Add Parameter for server with the IP address or FQDN of the nfs server
* Add Parameter for share with the path shared from the nfs server to clients

![Insert Screenshot](./images/media/add_storageclass2.png)

### Ensure the NFS Server is configured properly to allow ALL nodes of both source and destination clusters to mount the shared filesystem

# PV Migration

## Migrate PV to NFS on Source Cluster

>>>> **State:** Source PV on Source Cluster

### Create temporary migration namespace

```
kubectl create namespace migration
```

### Create PVC in nfs-storage-class 

* Match size of source pvc
* Set name to name of source pvc and append "-migrate"

#### source-pvc-migrate.yaml

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: source-pvc-migrate
  namespace: migration
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs-storage-class
```

```sh
kubectl apply -f source-pvc-migrate.yaml
```

### Clone Source PV to NFS PV

```
kubectl pv-migrate --source-namespace source-namespace --source source-pvc --dest-namespace migration --dest source-pvc-migrate --ignore-mounted
```

>>>> **State:** Source PV and cloned NFS PV on Source Cluster
  
## Migrate NFS PV to Destination cluster

### Gather NFS PV/PVC information and Source PVC yaml

```
export KUBECONFIG=/path/to/source_kubeconfig.yaml
```

```
kubectl get pv `kubectl get pvc source-pvc-migrate -n migration --no-headers | awk '{print $3}'` -o yaml |kubectl neat |grep -Ev 'resourceVersion:|uid:' > source-pv-migrate.yaml
```

```
kubectl get pvc source-pvc-migrate -n migration -o yaml |kubectl neat > source-pvc-migrate.yaml
```

```
kubectl get pvc source-pvc -o yaml |kubectl neat > source_pvc.yaml
```


### Setup NFS PV and new dest PVC on Destination Cluster

```
export KUBECONFIG=/path/to/destination_kubeconfig.yaml
```

### Create temporary migration namespace

```
kubectl create namespace migration
```

### Create namespace for application on Destination cluster (if it does not already exist)

```
kubectl create namespace source-namespace
```

### Create resources on the Destination cluster
```
kubectl apply -f source-pv-migrate.yaml
kubectl apply -f source-pvc-migrate.yaml
kubectl apply -f source_pvc.yaml
```

>>>> **State:** Source PV/PVC and cloned NFS PV/PVC on Source Cluster, NFS PV on Destination Cluster, Empty Destination PV/PVC
  
### Clone NFS PV to Destination PV

```
kubectl pv-migrate --source-namespace migrate --source source-pvc-migrate --dest-namespace source-namespace --dest source-pvc --ignore-mounted
```

>>>> **State:** Source PV/PVC and cloned NFS PV/PVC on Source Cluster, NFS PV on Destination Cluster, Populated Destination PV/PVC

# Deploy Apps 
## (Deployments/DaemonSets/StatefulSets/etc) that rely on the PV's
placeholder
# Cleanup
placeholder