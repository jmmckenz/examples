- [1. Install Observability](#1-install-observability)
  - [1.1. Install Helm](#11-install-helm)
  - [1.2. Configure helm repo](#12-configure-helm-repo)
  - [1.3. Setup values files](#13-setup-values-files)
  - [1.4. Create $VALUES\_DIR/suse-observability-values/templates/ingress\_values.yaml](#14-create-values_dirsuse-observability-valuestemplatesingress_valuesyaml)
  - [1.5. For smaller installations, edit sizing\_values.yaml](#15-for-smaller-installations-edit-sizing_valuesyaml)
    - [1.5.1. modify the line below from 10 to 50 (optional)](#151-modify-the-line-below-from-10-to-50-optional)
    - [1.5.2. Change all cpu requests to 50m to allow for operation on 4vcpu/16GB RAM 3-node cluster](#152-change-all-cpu-requests-to-50m-to-allow-for-operation-on-4vcpu16gb-ram-3-node-cluster)
  - [1.6. Create Namespace](#16-create-namespace)
  - [1.7. Create tls-obsv secretName](#17-create-tls-obsv-secretname)
  - [1.8. Install suse-observability](#18-install-suse-observability)
  - [1.9. Get initial admin password from baseConfig\_values.yaml comments](#19-get-initial-admin-password-from-baseconfig_valuesyaml-comments)
- [2. Initial setup of Observability](#2-initial-setup-of-observability)
  - [2.1. Installing UI extensions](#21-installing-ui-extensions)
  - [2.2. Get Api key and command line from observability CLI page to install STS CLI](#22-get-api-key-and-command-line-from-observability-cli-page-to-install-sts-cli)
  - [2.3. Retrieve service token](#23-retrieve-service-token)
  - [2.4. Configure UI extension](#24-configure-ui-extension)
  - [2.5. Setup StackPack for each cluster](#25-setup-stackpack-for-each-cluster)
    - [2.5.1. Generate a new token](#251-generate-a-new-token)
      - [2.5.1.1. Token needs to be generated at least once.  It can be reused for multiple clusters, or each cluster can have a unique token.](#2511-token-needs-to-be-generated-at-least-once--it-can-be-reused-for-multiple-clusters-or-each-cluster-can-have-a-unique-token)
- [3. Install Observability Agent on clusters](#3-install-observability-agent-on-clusters)
  - [3.1. Setup Repository](#31-setup-repository)
  - [3.2. Install Agent](#32-install-agent)

# 1. Install Observability
##  1.1. Install Helm
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```
## 1.2. Configure helm repo

```
helm repo add suse-observability https://charts.rancher.com/server-charts/prime/suse-observability
helm repo update
```

## 1.3. Setup values files 
Replace sizing profile with appropriate value for your environment

```
export VALUES_DIR=.
helm template \
  --set license='{SCC_REG_CODE}' \
  --set baseUrl='{BASE_URL_FOR_OBSERVABILITY}' \
  --set sizing.profile='10-nonha' \
  suse-observability-values \
  suse-observability/suse-observability-values --output-dir $VALUES_DIR
```

## 1.4. Create $VALUES_DIR/suse-observability-values/templates/ingress_values.yaml

```
ingress:
  enabled: true
  ingressClassName: nginx
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
  hosts:
    - host: {{BASE_URL_FOR_OBSERVABILITY}}
  tls:
    - hosts:
        - {{BASE_URL_FOR_OBSERVABILITY}}
      secretName: tls-obsv
```


## 1.5. For smaller installations, edit sizing_values.yaml  

### 1.5.1. modify the line below from 10 to 50 (optional)

```
CONFIG_FORCE_stackstate_agents_agentLimit: "50"
```

### 1.5.2. Change all cpu requests to 50m to allow for operation on 4vcpu/16GB RAM 3-node cluster 


## 1.6. Create Namespace

```
kubectl create namespace suse-observability
```

## 1.7. Create tls-obsv secretName

```
kubectl -n suse-observability create secret tls tls-obsv --cert=cert.pem --key=privkey.pem
```

## 1.8. Install suse-observability

```
helm upgrade --install \
  --namespace "suse-observability" \
  --values $VALUES_DIR/suse-observability-values/templates/ingress_values.yaml \
  --values $VALUES_DIR/suse-observability-values/templates/baseConfig_values.yaml \
  --values $VALUES_DIR/suse-observability-values/templates/sizing_values.yaml \
  suse-observability \
  suse-observability/suse-observability
```

## 1.9. Get initial admin password from baseConfig_values.yaml comments

example:
```
# Your SUSE Observability admin password is: pv48aEgN2cmbMfPf
```


# 2. Initial setup of Observability


## 2.1. Installing UI extensions
To install UI extensions, enable the UI extensions from the rancher UI

![Insert Screenshot](./images/media/rancherplugin1.png)

Install
After enabling UI extensions, follow these steps:

Navigate to extensions on the rancher UI and under the "Available" section of extensions, you will find the Observability extension.

Install the Observability extension.

Once installed, on the left panel of the rancher UI, the SUSE Observability section appears.

Follow the instructions as mentioned in Obtain a service token section below and fill in the details.

## 2.2. Get Api key and command line from observability CLI page to install STS CLI

![Insert Screenshot](./images/media/sts_cli.png)


## 2.3. Retrieve service token
Log into the SUSE Observability instance.

From the top left corner, select CLI.

Note the API token and install SUSE Observability cli on your local machine.
example:

```
curl -o- https://dl.stackstate.com/stackstate-cli/install.sh | STS_URL="https://obscluster.mchome-lab.duckdns.org" STS_API_TOKEN="wtADN67qd9fzX0Yy4EIxxyQiSH0tx17T" bash
```

Create a service token by running
```
sts service-token create --name suse-observability-extension --roles stackstate-k8s-troubleshooter --skip-ssl
```

example output:

```
✅ Service token created: svctok-9Lf6HvTZ1gzQQFtXlin09DRzV_pSLBbn
```

## 2.4. Configure UI extension
In Rancher, navigate to the SUSE Observability section and select "configurations". In this section, you can add the SUSE Observability server details and connect it using the URL and the the observability extension service token generated above.


## 2.5. Setup StackPack for each cluster

![Insert Screenshot](./images/media/stackpack1.png)

![Insert Screenshot](./images/media/stackpack2.png)

### 2.5.1. Generate a new token 
#### 2.5.1.1. Token needs to be generated at least once.  It can be reused for multiple clusters, or each cluster can have a unique token.

![Insert Screenshot](./images/media/stackpack3.png)

![Insert Screenshot](./images/media/stackpack4.png)


# 3. Install Observability Agent on clusters

## 3.1. Setup Repository

![Insert Screenshot](./images/media/add_observability_repo.png)

## 3.2. Install Agent

![Insert Screenshot](./images/media/apps_charts_filter_observability.png)

![Insert Screenshot](./images/media/apps_charts_install_observability.png)

![Insert Screenshot](./images/media/apps_charts_install_step1_observability.png)

![Insert Screenshot](./images/media/apps_charts_install_step2_observability.png)

* Cluster Name = {{identifier from StackPack setup}}
* SUSE Observability Ingest URL = https://{{ingest URL from StackPack setup}}
* SUSE Observability API Key = {{generated token from StackPack}}

![Insert Screenshot](./images/media/apps_charts_install_step3_observability.png)
