# Easy button psuedo-code (linux only):
# Use case: No existing CI/CD or plan to integrate CI/CD on new cluster later.

## Setup Environment Script
### Determine OS and assign package manager (zypper/yum/apt)
### Install git
### Install kubectl
### Install yq
### Install fzf
### Install krew
### Add krew to bashrc
### Add krew to running shell
### Update krew
### Install krew plugins
```
neat
resource-backup
get-all
grep
konfig
cs
eksporter
```

### Populate kubeconfigs for source and destination clusters
#### Download kubeconfigs from Rancher UI(s)
#### Add kubeconfigs to .kube/config
```
kubectl konfig import --save source-cluster-name.yaml
kubectl konfig import --save destination-cluster-name.yaml
```

## Backup Script/Function
### Args
```
--backup, -b            # If written as function
--cluster, -c           # Cluster name (required)
--plugin, -p            # plugin to use for gathering yamls (optional)
--out, -o               # directory to send resulting yamls (optional)
--yes, -y               # non-interactive, skip verification prompts
```

### Set context to source cluster
```
kubectl cs source-cluster:
```

### Determine plugin to use for gathering information:
```
none (yaml's will be unusable without editing)
neat (automated cleanup)
resource-backup (automated cleanup, default setting)
eksporter (automated cleanup)
resource-backup with neat
eksporter with neat
```

### Gather resources (assumption: all workload is namespaced scoped, no workloads running in default namespace)

#### Filtered Namespace names (no kube-system, cattle-*, local, tigera-operator, kube-public, kube-node-lease, calico-system, default, etc)

##### For each namespace, create a directory and gather resources
```
clusterrolebindings
clusterroles
config-maps (?)
crd
cronjobs
daemonsets
deployment
ingresses
priorityclasses
pv
pvc
rolebindings
roles
secrets
serviceaccounts
services
statefulsets
storageclasses
```

## Manual Review of yaml files, modifications, syntax corrections, redundancy exclusions
### Manually group deployments and related resources into subdirectories (optional)
#### Example 1: Group all namespace scoped shared resources like secrets or cronjobs into a separate directory
#### Example 2: Group all resources for "mywebapp" which consists of a deployment, service, and ingress into a separate directory.


## Restore Script/Function
### Args
```
--restore, -r           # If written as function
--cluster, -c           # Cluster name (required)
--in, -i                # directory to apply yamls from (optional)
--yes, -y               # non-interactive, skip verification prompts
```

### Set context to destination cluster
```
kubectl cs destination-cluster:
```

### Apply manifests from directory (./ by default or from --in)





