- [1. Prerequisites](#1-prerequisites)
- [2. Install NFS CSI Driver and Create a StorageClass](#2-install-nfs-csi-driver-and-create-a-storageclass)
  - [2.1. Create Repo](#21-create-repo)
    - [2.1.1. Option 1 - Create ClusterRepo from yaml (on source and destination)](#211-option-1---create-clusterrepo-from-yaml-on-source-and-destination)
      - [2.1.1.1. nfs-csi-repo.yaml](#2111-nfs-csi-repoyaml)
    - [2.1.2. Option 2 - Create ClusterRepo in Rancher UI](#212-option-2---create-clusterrepo-in-rancher-ui)
      - [2.1.2.1. Apps -\> Repositories -\> Create](#2121-apps---repositories---create)
      - [2.1.2.2. Populate data](#2122-populate-data)
  - [2.2. Creatae NFS Storage Class](#22-creatae-nfs-storage-class)
    - [2.2.1. Option 1 - Create StorageClass from yaml (on source and destination)](#221-option-1---create-storageclass-from-yaml-on-source-and-destination)
      - [2.2.1.1. example nfs-storageclass.yaml](#2211-example-nfs-storageclassyaml)
    - [2.2.2. Option 2 - Create StorageClass from Rancher UI](#222-option-2---create-storageclass-from-rancher-ui)
      - [2.2.2.1. Storage -\> StorageClasses -\> Create](#2221-storage---storageclasses---create)
      - [2.2.2.2. Populate data](#2222-populate-data)
    - [2.2.3. Ensure the NFS Server is configured properly to allow ALL nodes of both source and destination clusters to mount the shared filesystem](#223-ensure-the-nfs-server-is-configured-properly-to-allow-all-nodes-of-both-source-and-destination-clusters-to-mount-the-shared-filesystem)
- [3. PV Migration](#3-pv-migration)
  - [3.1. Migrate PV to NFS on Source Cluster](#31-migrate-pv-to-nfs-on-source-cluster)
    - [3.1.1. Create temporary migration namespace](#311-create-temporary-migration-namespace)
    - [3.1.2. Create PVC in nfs-storage-class](#312-create-pvc-in-nfs-storage-class)
      - [3.1.2.1. source-pvc-migrate.yaml](#3121-source-pvc-migrateyaml)
    - [3.1.3. Clone Source PV to NFS PV](#313-clone-source-pv-to-nfs-pv)
  - [3.2. Migrate NFS PV to Destination cluster](#32-migrate-nfs-pv-to-destination-cluster)
    - [3.2.1. Gather NFS PV/PVC information and Source PVC yaml](#321-gather-nfs-pvpvc-information-and-source-pvc-yaml)
    - [3.2.2. Setup NFS PV and new dest PVC on Destination Cluster](#322-setup-nfs-pv-and-new-dest-pvc-on-destination-cluster)
    - [3.2.3. Create temporary migration namespace](#323-create-temporary-migration-namespace)
    - [3.2.4. Create namespace for application on Destination cluster (if it does not already exist)](#324-create-namespace-for-application-on-destination-cluster-if-it-does-not-already-exist)
    - [3.2.5. Create resources on the Destination cluster](#325-create-resources-on-the-destination-cluster)
    - [3.2.6. Clone NFS PV to Destination PV](#326-clone-nfs-pv-to-destination-pv)
- [4. Deploy Apps](#4-deploy-apps)
  - [4.1. (Deployments/DaemonSets/StatefulSets/etc) that rely on the PV's](#41-deploymentsdaemonsetsstatefulsetsetc-that-rely-on-the-pvs)
- [5. Cleanup](#5-cleanup)

# 1. Prerequisites

* [krew Installation and Plugins](..\Tools\Krew.md)
  
  * Install all recommended krew plugins
  
* NFS filesystem shared to all nodes in the Source and Destination clusters

* kubeconfig files for both the Source and Destination clusters

* Perform PV/PVC Migrations **BEFORE** installing app yamls to insure the apps can mount the populated PV's

# 2. Install NFS CSI Driver and Create a StorageClass

## 2.1. Create Repo

### 2.1.1. Option 1 - Create ClusterRepo from yaml (on source and destination)

#### 2.1.1.1. nfs-csi-repo.yaml

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

### 2.1.2. Option 2 - Create ClusterRepo in Rancher UI

#### 2.1.2.1. Apps -> Repositories -> Create

![Insert Screenshot](./images/media/add_nfs_csi_repo1.png)

#### 2.1.2.2. Populate data

* Name
* Description (Optional)
* Index URL = https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts

![Insert Screenshot](./images/media/add_nfs_csi_repo2.png)

## 2.2. Creatae NFS Storage Class

### 2.2.1. Option 1 - Create StorageClass from yaml (on source and destination)

#### 2.2.1.1. example nfs-storageclass.yaml

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

### 2.2.2. Option 2 - Create StorageClass from Rancher UI

#### 2.2.2.1. Storage -> StorageClasses -> Create

![Insert Screenshot](./images/media/add_storageclass1.png)

#### 2.2.2.2. Populate data

* Name
* Description
* Provisioner = NFS(CSI)
* Add Parameter for server with the IP address or FQDN of the nfs server
* Add Parameter for share with the path shared from the nfs server to clients

![Insert Screenshot](./images/media/add_storageclass2.png)

### 2.2.3. Ensure the NFS Server is configured properly to allow ALL nodes of both source and destination clusters to mount the shared filesystem

# 3. PV Migration

## 3.1. Migrate PV to NFS on Source Cluster

>>>> **State:** Source PV on Source Cluster

### 3.1.1. Create temporary migration namespace

```
kubectl create namespace migration
```

### 3.1.2. Create PVC in nfs-storage-class 

* Match size of source pvc
* Set name to name of source pvc and append "-migrate"

#### 3.1.2.1. source-pvc-migrate.yaml

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

### 3.1.3. Clone Source PV to NFS PV

```
kubectl pv-migrate --source-namespace source-namespace --source source-pvc --dest-namespace migration --dest source-pvc-migrate --ignore-mounted
```

>>>> **State:** Source PV and cloned NFS PV on Source Cluster
  
## 3.2. Migrate NFS PV to Destination cluster

### 3.2.1. Gather NFS PV/PVC information and Source PVC yaml

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


### 3.2.2. Setup NFS PV and new dest PVC on Destination Cluster

```
export KUBECONFIG=/path/to/destination_kubeconfig.yaml
```

### 3.2.3. Create temporary migration namespace

```
kubectl create namespace migration
```

### 3.2.4. Create namespace for application on Destination cluster (if it does not already exist)

```
kubectl create namespace source-namespace
```

### 3.2.5. Create resources on the Destination cluster
```
kubectl apply -f source-pv-migrate.yaml
kubectl apply -f source-pvc-migrate.yaml
kubectl apply -f source_pvc.yaml
```

>>>> **State:** Source PV/PVC and cloned NFS PV/PVC on Source Cluster, NFS PV on Destination Cluster, Empty Destination PV/PVC
  
### 3.2.6. Clone NFS PV to Destination PV

```
kubectl pv-migrate --source-namespace migrate --source source-pvc-migrate --dest-namespace source-namespace --dest source-pvc --ignore-mounted
```

>>>> **State:** Source PV/PVC and cloned NFS PV/PVC on Source Cluster, NFS PV on Destination Cluster, Populated Destination PV/PVC

# 4. Deploy Apps 
## 4.1. (Deployments/DaemonSets/StatefulSets/etc) that rely on the PV's
placeholder
# 5. Cleanup
placeholder