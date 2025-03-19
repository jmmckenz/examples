
# Install RKE2 and Rancher

Verify /var/lib/rancher space on all nodes. Recommended 150GB -- 200GB.

## On First Control Plane Node:

### Populate config.yaml (Optional: See Note)
```
mkdir -p /etc/rancher/rke2/
vi /etc/rancher/rke2/config.yaml
```

 
```
token: my-shared-secret
tls-san:
  - rancher.mycompany.com
```

> RKE2 will create a config.yaml file on the first node if one does not exist.
> A token will be assigned and stored in:
>
> /var/lib/rancher/rke2/server/token
>
> The process above allows for the token to be predefined.
> The example "my-shared-token" will be used by the other nodes to join the cluster.  This token is interpreted literally, so it can have a plain text value or be a base64 encoded string.

### Install RKE2
```
curl -sfL https://get.rke2.io \| INSTALL_RKE2_TYPE=server sh -
systemctl enable rke2-server.service
systemctl start rke2-server.service
```
### Link kubectl and copy rke2.yaml to \~/.kube/
```
ln -s /var/lib/rancher/rke2/bin/kubectl /usr/local/bin/kubectl
cd /root
mkdir .kube
ln -s /etc/rancher/rke2/rke2.yaml .kube/config
chmod 600 .kube/config
```

## On Secondary Control Plane Nodes

### Populate config.yaml
```
mkdir -p /etc/rancher/rke2/
vi /etc/rancher/rke2/config.yaml
```
 
```
token: my-shared-secret
server: https://192.18.21.156:9345
tls-san:
  - rancher.mycompany.com
```
> If not using a prepopulated token like "my-shared-secret", use the
> token found in /var/lib/rancher/rke2/server/token from the Primary
> node.

### Install RKE2
```
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=server sh -
systemctl enable rke2-server.service
systemctl start rke2-server.service
```
### Link kubectl and copy rke2.yaml to \~/.kube/
```
ln -s /var/lib/rancher/rke2/bin/kubectl /usr/local/bin/kubectl
cd /root
mkdir .kube
ln -s /etc/rancher/rke2/rke2.yaml .kube/config
chmod 600 .kube/config
```
## On Node with kubectl access (can be a cluster node or remote node)

### Verify Status of Cluster
```
kubectl get nodes
```
```
[root@rancher01 ~]# kubectl get nodes
NAME         STATUS   ROLES                       AGE   VERSION
rancher01   Ready    control-plane,etcd,master   88m   v1.25.10+rke2r1
rancher02   Ready    control-plane,etcd,master   80m   v1.25.10+rke2r1
rancher03   Ready    control-plane,etcd,master   80m   v1.25.10+rke2r1
```
### Install Helm
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```
### Install Helm Repos
```
helm repo add rancher-prime https://charts.rancher.com/server-charts/prime
```
```
helm repo add jetstack https://charts.jetstack.io
```
### Install cert-manager CRD

> Verify latest release of cert manager at
> <https://github.com/cert-manager/cert-manager>
```
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.17.1/cert-manager.crds.yaml
```
### Install cert-manager
```
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.17.1
```
### Install Rancher 
```
helm install rancher rancher-prime/rancher --create-namespace --namespace cattle-system --set hostname=rancher.mycompany.com --set bootstrapPassword=rancher --set global.cattle.psp.enabled=false
```
### Install Rancher with a signed cert

Create namespace and tls-rancher-ingress secret from crt and key
```
kubectl create namespace cattle-system
kubectl -n cattle-system create secret tls tls-rancher-ingress \
  --cert=\$PATH_TO_CERT/tls.crt \
  --key=\$PATH_TO_CERT/tls.key
```
```
helm install rancher rancher-prime/rancher --create-namespace --namespace cattle-system --set hostname=rancher.mycompany.com --set bootstrapPassword=rancher --set global.cattle.psp.enabled=false --set ingress.tls.source=secret
```
### Install Rancher with a signed cert from a Private CA

Create namespace, tls-rancher-ingress secret, and tls-ca secret from
crt, key and Private CA root pem.
```
kubectl create namespace cattle-system
kubectl -n cattle-system create secret tls tls-rancher-ingress \
  --cert=\$PATH_TO_CERT/tls.crt \
  --key=\$PATH_TO_CERT/tls.key
```
```
kubectl -n cattle-system create secret generic tls-ca \
  --from-file=cacerts.pem
```
```
helm install rancher rancher-prime/rancher --create-namespace --namespace cattle-system --set hostname=rancher.mycompany.com --set bootstrapPassword=rancher --set global.cattle.psp.enabled=false --set ingress.tls.source=secret --set privateCA=true
```
## Monitor Status of Rancher Deployment
```
kubectl get pods -n cattle-system
```
```
[root@rancher01 ~]# kubectl get pods -n cattle-system
NAME                               READY   STATUS      RESTARTS   AGE
helm-operation-gxgbn               0/2     Completed   0          32m
rancher-75b4c59769-jvwt4           1/1     Running     0          79m
rancher-75b4c59769-kznbx           1/1     Running     0          79m
rancher-75b4c59769-mrfhk           1/1     Running     0          79m
rancher-webhook-64666d6db6-nfq7t   1/1     Running     0          76m
```
> You should see 3 rancher pods, 1 rancher-webhook pod, and possibly some transient helm-operation pods used by the system to install the components of rancher from the helm chart. 

## Log locations and other files of interest found on the RKE2 control-plane nodes

/var/lib/rancher/rke2/agent/logs/
/var/lib/rancher/rke2/agent/containerd/containerd.log
/var/lib/rancher/rke2/server/db/etcd/member/snap  #location of automatic etcd DB snapshots
/var/lib/rancher/rke2/server/token  #file containing the token used byother nodes to join the cluster (as seen in config.yaml)
/var/lib/rancher/rke2/server/manifests/  #location to place manifests for auto deployment to the cluster

# Rancher Upgrade

## Backup Rancher

[\*\*\*\* Add section for Airgap considerations \*\*\*\*]{.mark}

### Take a Rancher Backup via the Rancher Backup Operator. 

Install Rancher Backup Operator through UI

or

Install Rancher Backup Operator through command-line

> ref Section 1:
>
> <https://ranchermanager.docs.rancher.com/how-to-guides/new-user-guides/backup-restore-and-disaster-recovery/migrate-rancher-to-new-cluster#1-install-the-rancher-backup-helm-chart>

## Verify availability of helm repository
```
helm repo list
```
## Update helm repository
```
helm repo update
```
## Retrieve Helm Options

Make sure you save the \--set options you used during the initial
install. You will need to use the same options when you upgrade Rancher to new versions with Helm.
```
helm -n cattle-system get values rancher
```
```
helm -n cattle-system get values rancher > values.yaml
```
> Edit the values.yaml and remove the bootstrapPassword line to preserve the admin password if it was changed after initial installation.
>
> Save values.yaml to some kind of source control (git) as an artifact for your system builds if not already done.

## Upgrade Rancher

### Run the upgrade helm command.
```
helm upgrade rancher rancher-prime/rancher --namespace cattle-system --set hostname=rancher.company.com  --set otheroptions=value --set global.cattle.psp.enabled=false --version v2.10.3
```
or
```
helm upgrade rancher rancher-prime/rancher --namespace cattle-system --version v2.10.3 -f values.yaml
```
### Monitor the new deployment.
```
kubectl get pods -n cattle-system -w
```
Once all the new rancher pods and rancher-webhook pod are in a Ready
state, log into the UI and verify the appropriate Rancher version is showing in the \"about\" dashboard.

https://rancher.mycompany.com/dashboard/about

> You will also find the most up to date versions of the Rancher CLI on the \"about\" page for download.

# **Upgrade** RKE2

## Upgrade Rancher Management Server RKE2 Version

### Navigate to Cluster Management

![A screenshot of a computer Description automatically
generated](./images/media/image1.png)

### From the Clusters Menu

> Edit Config for the local cluster

![A screenshot of a computer Description automatically
generated](./images/media/image2.png)

[\*\*\*\*ADD SECTION FOR CLUSTER OWNER \*\*\*\*]{.mark}

### Select the version of RKE2 from the pull down and click Save

![A screenshot of a computer Description automatically
generated](./images/media/image3.png)

## Upgrade Downstream Cluster RKE2 Version

### Navigate to Cluster Management

![A screenshot of a computer Description automatically
generated](./images/media/image1.png)

### From the Clusters Menu

> Edit Config for the downstream cluster

![A screenshot of a computer Description automatically
generated](./images/media/image4.png)

### Select the version of RKE2 from the pull down and click Save

![A screenshot of a computer Description automatically
generated](./images/media/image5.png)

[\*\*\*\* ADD SECTION FOR RKE2 STANDALONE CLUSTER UPGRADES AIRGAP and
NORMAL \*\*\*\*]{.mark}

# Downstream Cluster Build

## Custom Cluster Registration from GUI

### Navigate to Cluster Management

![A screenshot of a computer Description automatically
generated](./images/media/image1.png)

### From the Clusters Menu Click Create

![A screenshot of a computer Description automatically
generated](./images/media/image6.png)

### From Cluster Create Menu Click Custom

![A screenshot of a computer Description automatically
generated](./images/media/image7.png)

### Create Cluster

> Provide a Cluster Name, desired RKE2 version, and any other customized information
>
> Click Create

![A screenshot of a computer Description automatically
generated](./images/media/image8.png)

### The resulting page once the Cluster resource is created

> Check the box next to "Insecure" if you need to skip TLS verification
>
> Check or Uncheck the appropriate boxes for cluster roles to generate commands for each type of node. Windows Powershell commands will not populate until there is at least one LINUX based Controlplane/etcd node joined to the newly created cluster.

![A screenshot of a computer Description automatically
generated](./images/media/image9.png)

## Custom Cluster Registration from API calls

### Creating Cluster through Rancher CLI or by API call documentation

<https://www.suse.com/support/kb/doc/?id=000020121>

### Example for getting custom cluster registration command:

\* Rancher URI = rancher.mycompany.com

\* Downstream Cluster name = downstream001

### Get Cluster ID (returns rancher generated clusterid c-m-shw7c57m)
```
curl --insecure https://rancher.mycompany.com/v3/clusters?name=downstream001 -H 'content-type: application/json' -H "Authorization: Bearer token-hq8pw:9fkjfz85qfl7cxhzzm2d5jqbgf6x4fk4ng5md9g9msk6vtdgmws9bs"--insecure |jq -r .data[].id
```
### Get Cluster Registration Curl Commands

The following commands will return the curl command needed for joining base OS images to the downstream cluster. Alternatives to these commands would be nodeCommand and windowsNodeCommand to remove the "--insecure" from the returned curl command...

#### Controlplane, Etcd
```
curl --insecure https://rancher.mycompany.com/v3/clusters/c-m-shw7c57m/clusterregistrationtokens -H 'content-type: application/json' -H "Authorization: Bearer token-hq8pw:9fkjfz85qfl7cxhzzm2d5jqbgf6x4fk4ng5md9g9msk6vtdgmws9bs" --insecure |jq -r '.data[] |select(.name |contains("crt-")) | .insecureNodeCommand + " --controlplane --etcd"'
```
#### Controlplane, Etcd, and Worker
```
curl --insecure https://rancher.mycompany.com/v3/clusters/c-m-shw7c57m/clusterregistrationtokens -H 'content-type: application/json' -H "Authorization: Bearer token-hq8pw:9fkjfz85qfl7cxhzzm2d5jqbgf6x4fk4ng5md9g9msk6vtdgmws9bs" --insecure |jq -r '.data[] |select(.name |contains("crt-")) | .insecureNodeCommand + " --controlplane --etcd --worker"'
```
#### Worker Only
```
curl --insecure https://rancher.mycompany.com/v3/clusters/c-m-shw7c57m/clusterregistrationtokens -H 'content-type: application/json' -H "Authorization: Bearer token-hq8pw:9fkjfz85qfl7cxhzzm2d5jqbgf6x4fk4ng5md9g9msk6vtdgmws9bs" --insecure |jq -r '.data[] |select(.name |contains("crt-")) | .insecureNodeCommand + " --worker"'
```
#### Windows Node
```
curl --insecure https://rancher.mycompany.com/v3/clusters/c-m-shw7c57m/clusterregistrationtokens -H 'content-type: application/json' -H "Authorization: Bearer token-hq8pw:9fkjfz85qfl7cxhzzm2d5jqbgf6x4fk4ng5md9g9msk6vtdgmws9bs" --insecure |jq -r '.data[] |select(.name |contains("crt-")) | .insecureWindowsNodeCommand 
```
### Example Output:
```
[root@rancher01 ~]#  curl --insecure https://rancher.mycompany.com/v3/clusters?name=downstream001 -H 'content-type: application/json' -H "Authorization: Bearer token-hq8pw:9fkjfz85qfl7cxhzzm2d5jqbgf6x4fk4ng5md9g9msk6vtdgmws9bs" --insecure |jq -r .data[].id
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 15538    0 15538    0     0   176k      0 --:--:-- --:--:-- --:--:--  174k
c-m-shw7c57m
```
```
[root@rancher01 ~]# curl --insecure https://rancher.mycompany.com/v3/clusters/c-m-shw7c57m/clusterregistrationtokens -H 'content-type: application/json' -H "Authorization: Bearer token-hq8pw:9fkjfz85qfl7cxhzzm2d5jqbgf6x4fk4ng5md9g9msk6vtdgmws9bs" --insecure |jq -r '.data[] |select(.name |contains("crt-")) | .insecureNodeCommand + " --controlplane --etcd"'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 10861    0 10861    0     0  95271      0 --:--:-- --:--:-- --:--:-- 94443
 curl --insecure -fL https://rancher.mycompany.com/system-agent-install.sh | sudo  sh -s - --server https://rancher.mycompany.com --label 'cattle.io/os=linux' --token 5q2499v9xlqfhvsjrblkzw2dnq5kz5275h54gsb5nnfc665cv2kvtt --ca-checksum 5c02c9d41756c2cae614be39ac9444ec093d3a69a7b1edc931223a7f5391353c --controlplane --etcd
```
```
[root@rancher01 ~]# curl --insecure https://rancher.mycompany.com/v3/clusters/c-m-shw7c57m/clusterregistrationtokens -H 'content-type: application/json' -H "Authorization: Bearer token-hq8pw:9fkjfz85qfl7cxhzzm2d5jqbgf6x4fk4ng5md9g9msk6vtdgmws9bs" --insecure |jq -r '.data[] |select(.name |contains("crt-")) | .insecureNodeCommand + " --control-plane --etcd --worker"'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 10861    0 10861    0     0   134k      0 --:--:-- --:--:-- --:--:--  135k
 curl --insecure -fL https://rancher.mycompany.com/system-agent-install.sh | sudo  sh -s - --server https://rancher.mycompany.com --label 'cattle.io/os=linux' --token 5q2499v9xlqfhvsjrblkzw2dnq5kz5275h54gsb5nnfc665cv2kvtt --ca-checksum 5c02c9d41756c2cae614be39ac9444ec093d3a69a7b1edc931223a7f5391353c --control-plane --etcd --worker
```
```
[root@rancher01 ~]# curl --insecure https://rancher.mycompany.com/v3/clusters/c-m-shw7c57m/clusterregistrationtokens -H 'content-type: application/json' -H "Authorization: Bearer token-hq8pw:9fkjfz85qfl7cxhzzm2d5jqbgf6x4fk4ng5md9g9msk6vtdgmws9bs" --insecure |jq -r '.data[] |select(.name |contains("crt-")) | .insecureNodeCommand + " --worker"'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 10861    0 10861    0     0   173k      0 --:--:-- --:--:-- --:--:--  173k
 curl --insecure -fL https://rancher.mycompany.com/system-agent-install.sh | sudo  sh -s - --server https://rancher.mycompany.com --label 'cattle.io/os=linux' --token 5q2499v9xlqfhvsjrblkzw2dnq5kz5275h54gsb5nnfc665cv2kvtt --ca-checksum 5c02c9d41756c2cae614be39ac9444ec093d3a69a7b1edc931223a7f5391353c --worker
```
```
[root@rancher01 ~]# curl --insecure https://rancher.mycompany.com/v3/clusters/c-m-shw7c57m/clusterregistrationtokens -H 'content-type: application/json' -H "Authorization: Bearer token-hq8pw:9fkjfz85qfl7cxhzzm2d5jqbgf6x4fk4ng5md9g9msk6vtdgmws9bs" --insecure |jq -r '.data[] |select(.name |contains("crt-")) | .insecureWindowsNodeCommand'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 10861    0 10861    0     0   165k      0 --:--:-- --:--:-- --:--:--  165k
 curl.exe --insecure -fL https://rancher.mycompany.com/wins-agent-install.ps1 -o install.ps1; Set-ExecutionPolicy Bypass -Scope Process -Force; ./install.ps1 -Server https://rancher.mycompany.com -Label 'cattle.io/os=windows' -Token 5q2499v9xlqfhvsjrblkzw2dnq5kz5275h54gsb5nnfc665cv2kvtt -Worker -CaChecksum 5c02c9d41756c2cae614be39ac9444ec093d3a69a7b1edc931223a7f5391353c
```
# Longhorn Backup To MINIO

REF:
<https://oopflow.medium.com/how-to-backup-longhorn-to-minio-s3-9c8c126ae92e>

## Longhorn MINIO Setup

### Create Minio Bucket

> Example: daily-longhorn-backup

### Create Access Key and Secret Key

### In Minio settings

Set a Region to onprep-sp

Set Description for Region

### Recorded Information So Far
```
Bucket Name: daily-longhorn-backup
Url: http://minio.mycompany.com:9000/
AccessKey: \<FROM_MINIO_UI\>
SecretKey: \<FROM_MINIO_UI\>
Region: us-east-01
```
### Encode information for use in creating secret
```
echo -n http://minio.mycompany.com:9000/ \|base64
echo -n ACCESSKEY \|base64
echo -n SECRETKEY \|base64
```
### Create Secret longhorn-minio-credential.yaml
```
apiVersion: v1
kind: Secret
metadata:
  name: longhorn-minio-credentials
  namespace: longhorn-system
type: Opaque
data:
  AWS_ACCESS_KEY_ID: BASE64_OF_ACCESSKEY
  AWS_SECRET_ACCESS_KEY: BASE64_OF_SECRETKEY
  AWS_ENDPOINTS: BASE64_OF_URL
```
### Apply secret
```
kubectl apply -f longhorn-minio-credentials.yaml
```
### Configure Longhorn for Backups

#### In Longhorn Settings (General Settings Page) scroll down to Backup Target

![A screenshot of a computer Description automatically
generated](./images/media/image10.png)

#### Modify the Backup Target and Credential

![A screenshot of a computer Description automatically
generated](./images/media/image11.png)

Backup Target

    s3://daily-longhorn-backup@us-east-01/

Backup Target Credential

    longhorn-minio-credentials

# Harbor Installation via HELM

REF: <https://github.com/goharbor/harbor-helm/blob/main/values.yaml>

> Rancher Values line numbers do not match the values.yaml in the helm chart in the Rancher GUI.
>
> Line numbers below are approximate.

## Install Harbor from Rancher Partner Charts

### Create Namespace for Harbor Installation

> Create namespace in the gui or with the following kubectl command
```
kubectl create namespace harbor
```
### From Rancher UI Navigate to Apps 🡪 Charts

Select Partner Charts From the Pulldown and Filter by Harbor as shown
below

Click on Harbor Chart to initiate installation

![A screenshot of a computer Description automatically
generated](./images/media/image12.png)

### Click Install

![A screenshot of a computer Description automatically
generated](./images/media/image13.png)

### Enter namespace and deployment name for harbor and click Next

![A screenshot of a computer Description automatically
generated](./images/media/image14.png)

## Modify Harber Values

![A screenshot of a computer Description automatically
generated](./images/media/image15.png)

### Customize helm values for installation.

Lines ~128-134 (Optional)
```
Setup TLS cert info.

Provide secret name that contains the tls.key and tls.crt the harbor URL

If providing your own cert/secret, set line 134 "certSource: secret"

If left blank, will create a secret and cert pair via certmanager called "harbor-ingress"

Can be changed manually later by updating the ingress to use a different secret.
```
Line ~109 & ~136 (Required)
```
Set the URL for the harbor core instance.
```
Line ~137 (Optional)
```
Default Harbor12345
```
Recommended to change this either during install or through Harbor UI

Line ~264 persistentVolumeClaim (Optional/Recommended)
```
Sets the sizing for the PVC\'s that will get created by the chart. If
the storageClass for a particular PVC is not set implicitly, the default storage class (in this case longhorn) will be used to create the appropriate PV's.

Set appropriate sizes for PV's
```
### Consider changing passwords

Any default passwords for the DB/redis/etc should be changed at INSTALL

Line ~57: 
```
Internal Postgres password
```
Line ~364: 
```
registry password
```
Line ~396: 
```
secretKey set to "not-a-secure-key"
```
### Update Node Selectors

> Note: Line numbers will shift as you add Node Selectors

Line 16 
```
Core 🡪 zone: infra
```
Line 57
```
Database 🡪 storage: data
```
Line 83
```
Exporter 🡪 zone: infra
```
Line 184
```
Job Service 🡪 zone: infra
```
Line 229
```
nginx 🡪 zone: infra
```
Line 314
```
portal 🡪 zone: infra
```
Line 351
```
redis 🡪 zone: infra
```
Line 382
```
registry 🡪 zone: infra
```
Line 429
```
Trivy 🡪 zone: infra
```
### Other lines of interest

Lines ~236-263
```
Possibly be able to setup image storage outside of Kubernetes or to
MINIO instance.

Defaults to \"filesystem\" which I will assume means to a PV that is
setup for the instance.
```
### See Appendix A for example values file

## Perform Install

### Click Install once all edits have been made to the values

![A screenshot of a computer Description automatically
generated](./images/media/image15.png)

# Neuvector Installation

[\*\*\*\* Needs Rewrite to reflect changes in deployment instructions \*\*\*\*]{.mark}

## Create the neuvector project

To create a new project, click the Create Project button on the top
right corner.

> Project: Create page will be displayed.

For the project Name, enter:

> neuvector

Click the Create button on the bottom right corner.

> The new project will be available in the bottom of the list displayed.

## Install Nuevector from Cluster Tools

From the bottom left corner, click the Cluster Tools button.

From the list of applications, locate NeuVector.

Click the Install button.

> An Install: Step 1 form will be displayed.
>
> Feel free to read the information provided for the NeuVector Helm
> chart.

For the Install into Project dropdown menu, select neuvector.

From the bottom right, click the Next button.

From the form menu items on the left, click the Container Runtime link.

> Container Runtime information will be displayed.

Deselect Docker Runtime.

Select k3s Containerd Runtime.

> Verify the Runtime Path is /run/k3s/containerd/containerd.sock

From the form menu items on the left, click PVC Configuration.

Enter/select the following information:

> PVC Status: (selected)
>
> Storage Class Name: longhorn

From the form menu items on the left, click Service Configuration.

From the Manager Service Type dropdown menu, select ClusterIP.

To launch the SUSE NeuVector deployment, click the Install button on the
bottom right.

> A chart deployment tab will be opened in the bottom part of the
> browser
>
> window. It will take a couple of minutes for the deployment to
> complete.

Close the deployment tab.
[\*\*\*\* Dead link to youtube video \*\*\*\*]{.mark}
> Ref: <https://www.youtube.com/watch?v=jgkgEpel_98>

# Rolling Restart Procedure

## Restart Rancher Management Cluster

### Control-Plane

Restart one node at a time

Graceful shutdown and reboot of a node should accomplish a clean
shutdown of RKE2

For situations when a reboot is not necessary, can restart from the
command line:
```
systemctl restart rke2-server
```
## Restart Downstream Cluster

### Control-Plane

Restart control-planes one node at a time

Graceful shutdown and reboot of a node should accomplish a clean
shutdown of RKE2

For situations when a reboot is not necessary, can restart from the
command line:
```
systemctl restart rke2-server
```
### Worker

Restart one node at a time

Graceful shutdown and reboot of a node should accomplish a clean
shutdown of RKE2

For situations when a reboot is not necessary, can restart from the
command line:
```
systemctl restart rke2-agent
```
# Shutdown and Startup

Perform the following tasks on all Downstream clusters first. Then
perform the ControlPlane tasks for the Rancher Management Server nodes.

## Shutdown

### Shutdown Worker Nodes 

ssh into the worker node

stop rke2-agent
```
systemctl stop rke2-agent
```
shutdown the system
```
shutdown now
```
### Shutdown ControlPlane Nodes One At A Time

ssh into the controlplane node

stop rke2-server
```
systemctl stop rke2-server
```
shutdown the system
```
shutdown now
```
## Startup

### Startup ControlPlane Nodes One At A Time

Power on the system

ssh into the controlplane node

check status of rke2-server
```
systemctl status rke2-server
```
### Startup Worker Nodes

Power on the system

ssh into the worker node

check status of rke2-agent
```
systemctl status rke2-agent
```
# Rancher App Charts

## Rancher provided Helm Charts

Rancher provides a number of application charts as well as Partner charts for useful applications. Some applications are only visible on the Rancher local cluster, while other utilities such as Longhorn and Logging are available for installation on downstream clusters as well.

![A screenshot of a computer Description automatically
generated](./images/media/image16.png)

## Recommended Tools

1.  Longhorn (Opensource with paid support option)
2.  Nuevector (Opensource with paid support option)
3.  CIS Benchmark
4.  Alerting Drivers
5.  Logging
6.  Monitoring
7.  Rancher Backup (local cluster only)

> Descriptions of these tools as well as Partner applications can be
> found by selecting any of the Apps from Apps 🡪 Charts on both the
> local and downstream clusters.

# APPENDIX A -- Harbor Values
```
caSecretName: ''
cache:
  enabled: false
  expireHours: 24
core:
  affinity: {}
  artifactPullAsyncFlushDuration: null
  automountServiceAccountToken: false
  configureUserSettings: null
  extraEnvVars: []
  gdpr:
    deleteUser: false
  image:
    repository: goharbor/harbor-core
    tag: v2.9.1
  nodeSelector:
    zone: infra
  podAnnotations: {}
  podLabels: {}
  priorityClassName: null
  quotaUpdateProvider: db
  replicas: 1
  revisionHistoryLimit: 10
  secret: ''
  secretName: ''
  serviceAccountName: ''
  serviceAnnotations: {}
  startupProbe:
    enabled: true
    initialDelaySeconds: 10
  tokenCert: ''
  tokenKey: ''
  tolerations: []
  topologySpreadConstraints: []
  xsrfKey: ''
database:
  external:
    coreDatabase: registry
    existingSecret: ''
    host: 192.168.0.1
    password: password
    port: '5432'
    sslmode: disable
    username: user
  internal:
    affinity: {}
    automountServiceAccountToken: false
    extraEnvVars: []
    image:
      repository: goharbor/harbor-db
      tag: v2.9.1
    initContainer:
      migrator: {}
      permissions: {}
    livenessProbe:
      timeoutSeconds: 1
    nodeSelector:
      storage: data
    password: HbR2024@SuSE
    priorityClassName: null
    readinessProbe:
      timeoutSeconds: 1
    serviceAccountName: ''
    shmSizeLimit: 512Mi
    tolerations: []
  maxIdleConns: 100
  maxOpenConns: 900
  podAnnotations: {}
  podLabels: {}
  type: internal
enableMigrateHelmHook: false
existingSecretAdminPasswordKey: HARBOR_ADMIN_PASSWORD
existingSecretSecretKey: ''
exporter:
  affinity: {}
  automountServiceAccountToken: false
  cacheCleanInterval: 14400
  cacheDuration: 23
  extraEnvVars: []
  image:
    repository: goharbor/harbor-exporter
    tag: v2.9.1
  nodeSelector:
    zone: infra
  podAnnotations: {}
  podLabels: {}
  priorityClassName: null
  replicas: 1
  revisionHistoryLimit: 10
  serviceAccountName: ''
  tolerations: []
  topologySpreadConstraints: []
expose:
  clusterIP:
    annotations: {}
    name: harbor
    ports:
      httpPort: 80
      httpsPort: 443
  ingress:
    annotations:
      ingress.kubernetes.io/proxy-body-size: '0'
      ingress.kubernetes.io/ssl-redirect: 'true'
      nginx.ingress.kubernetes.io/proxy-body-size: '0'
      nginx.ingress.kubernetes.io/ssl-redirect: 'true'
    className: ''
    controller: default
    harbor:
      annotations: {}
      labels: {}
    hosts:
      core: harbor.mycompany.com
    kubeVersionOverride: ''
  loadBalancer:
    IP: ''
    annotations: {}
    name: harbor
    ports:
      httpPort: 80
      httpsPort: 443
    sourceRanges: []
  nodePort:
    name: harbor
    ports:
      http:
        nodePort: 30002
        port: 80
      https:
        nodePort: 30003
        port: 443
  tls:
    auto:
      commonName: ''
    certSource: secret
    enabled: true
    secret:
      secretName: 'harbor-cert-secret'
  type: ingress
externalURL: https://harbor.mycompany.com
harborAdminPassword: Harbor12345
imagePullPolicy: IfNotPresent
imagePullSecrets: null
internalTLS:
  certSource: auto
  core:
    crt: ''
    key: ''
    secretName: ''
  enabled: false
  jobservice:
    crt: ''
    key: ''
    secretName: ''
  portal:
    crt: ''
    key: ''
    secretName: ''
  registry:
    crt: ''
    key: ''
    secretName: ''
  strong_ssl_ciphers: false
  trivy:
    crt: ''
    key: ''
    secretName: ''
  trustCa: ''
ipFamily:
  ipv4:
    enabled: true
  ipv6:
    enabled: true
jobservice:
  affinity: {}
  automountServiceAccountToken: false
  extraEnvVars: []
  image:
    repository: goharbor/harbor-jobservice
    tag: v2.9.1
  jobLoggers:
    - file
  loggerSweeperDuration: 14
  maxJobWorkers: 10
  nodeSelector:
    zone: infra
  notification:
    webhook_job_http_client_timeout: 3
    webhook_job_max_retry: 3
  podAnnotations: {}
  podLabels: {}
  priorityClassName: null
  reaper:
    max_dangling_hours: 168
    max_update_hours: 24
  replicas: 1
  revisionHistoryLimit: 10
  secret: ''
  serviceAccountName: ''
  tolerations: []
  topologySpreadConstraints: null
logLevel: info
metrics:
  core:
    path: /metrics
    port: 8001
  enabled: false
  exporter:
    path: /metrics
    port: 8001
  jobservice:
    path: /metrics
    port: 8001
  registry:
    path: /metrics
    port: 8001
  serviceMonitor:
    additionalLabels: {}
    enabled: false
    interval: ''
    metricRelabelings: []
    relabelings: []
nginx:
  affinity: {}
  automountServiceAccountToken: false
  extraEnvVars: []
  image:
    repository: goharbor/nginx-photon
    tag: v2.9.1
  nodeSelector:
    zone: infra
  podAnnotations: {}
  podLabels: {}
  priorityClassName: null
  replicas: 1
  revisionHistoryLimit: 10
  serviceAccountName: ''
  tolerations: []
  topologySpreadConstraints: []
persistence:
  enabled: true
  imageChartStorage:
    azure:
      accountkey: base64encodedaccountkey
      accountname: accountname
      container: containername
      existingSecret: ''
    disableredirect: false
    filesystem:
      rootdirectory: /storage
    gcs:
      bucket: bucketname
      encodedkey: base64-encoded-json-key-file
      existingSecret: ''
      useWorkloadIdentity: false
    oss:
      accesskeyid: accesskeyid
      accesskeysecret: accesskeysecret
      bucket: bucketname
      region: regionname
    s3:
      bucket: bucketname
      region: us-west-1
    swift:
      authurl: https://storage.myprovider.com/v3/auth
      container: containername
      password: password
      username: username
    type: filesystem
  persistentVolumeClaim:
    database:
      accessMode: ReadWriteOnce
      annotations: {}
      existingClaim: ''
      size: 10Gi
      storageClass: ''
      subPath: ''
    jobservice:
      jobLog:
        accessMode: ReadWriteOnce
        annotations: {}
        existingClaim: ''
        size: 1Gi
        storageClass: ''
        subPath: ''
    redis:
      accessMode: ReadWriteOnce
      annotations: {}
      existingClaim: ''
      size: 1Gi
      storageClass: ''
      subPath: ''
    registry:
      accessMode: ReadWriteOnce
      annotations: {}
      existingClaim: ''
      size: 200Gi
      storageClass: ''
      subPath: ''
    trivy:
      accessMode: ReadWriteOnce
      annotations: {}
      existingClaim: ''
      size: 5Gi
      storageClass: ''
      subPath: ''
  resourcePolicy: keep
portal:
  affinity: {}
  automountServiceAccountToken: false
  extraEnvVars: []
  image:
    repository: goharbor/harbor-portal
    tag: v2.9.1
  nodeSelector:
    zone: infra
  podAnnotations: {}
  podLabels: {}
  priorityClassName: null
  replicas: 1
  revisionHistoryLimit: 10
  serviceAccountName: ''
  tolerations: []
  topologySpreadConstraints: []
proxy:
  components:
    - core
    - jobservice
    - trivy
  httpProxy: null
  httpsProxy: null
  noProxy: 127.0.0.1,localhost,.local,.internal
redis:
  external:
    addr: 192.168.0.2:6379
    coreDatabaseIndex: '0'
    existingSecret: ''
    jobserviceDatabaseIndex: '1'
    password: ''
    registryDatabaseIndex: '2'
    sentinelMasterSet: ''
    trivyAdapterIndex: '5'
    username: ''
  internal:
    affinity: {}
    automountServiceAccountToken: false
    extraEnvVars: []
    image:
      repository: goharbor/redis-photon
      tag: v2.9.1
    jobserviceDatabaseIndex: '1'
    nodeSelector:
      zone: infra
    priorityClassName: null
    registryDatabaseIndex: '2'
    serviceAccountName: ''
    tolerations: []
    trivyAdapterIndex: '5'
  podAnnotations: {}
  podLabels: {}
  type: internal
registry:
  affinity: {}
  automountServiceAccountToken: false
  controller:
    extraEnvVars: []
    image:
      repository: goharbor/harbor-registryctl
      tag: v2.9.1
  credentials:
    existingSecret: ''
    password: HbR2024@SuSE
    username: harbor_registry_user
  middleware:
    cloudFront:
      baseurl: example.cloudfront.net
      duration: 3000s
      ipfilteredby: none
      keypairid: KEYPAIRID
      privateKeySecret: my-secret
    enabled: false
    type: cloudFront
  nodeSelector:
    zone: infra
  podAnnotations: {}
  podLabels: {}
  priorityClassName: null
  registry:
    extraEnvVars: []
    image:
      repository: goharbor/registry-photon
      tag: v2.9.1
  relativeurls: false
  replicas: 1
  revisionHistoryLimit: 10
  secret: ''
  serviceAccountName: ''
  tolerations: []
  topologySpreadConstraints: []
  upload_purging:
    age: 168h
    dryrun: false
    enabled: true
    interval: 24h
secretKey: HbR2024@SuSE
trace:
  enabled: false
  jaeger:
    endpoint: http://hostname:14268/api/traces
  otel:
    compression: false
    endpoint: hostname:4318
    insecure: true
    timeout: 10
    url_path: /v1/traces
  provider: jaeger
  sample_rate: 1
trivy:
  affinity: {}
  automountServiceAccountToken: false
  debugMode: false
  enabled: true
  extraEnvVars: []
  gitHubToken: ''
  ignoreUnfixed: false
  image:
    repository: goharbor/trivy-adapter-photon
    tag: v2.9.1
  insecure: false
  nodeSelector:
    zone: infra
  offlineScan: false
  podAnnotations: {}
  podLabels: {}
  priorityClassName: null
  replicas: 1
  resources:
    limits:
      cpu: 1
      memory: 1Gi
    requests:
      cpu: 200m
      memory: 512Mi
  securityCheck: vuln
  serviceAccountName: ''
  severity: UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL
  skipUpdate: false
  timeout: 5m0s
  tolerations: []
  topologySpreadConstraints: []
  vulnType: os,library
updateStrategy:
  type: RollingUpdate
```

# Appendix B - Logging Configs

Secrets used for authentication need to be created manually.

Additional configuration information can be found here:
<https://kube-logging.dev/docs/configuration/>

or

[Rancher Documentation - Flows and Cluster Flows](https://ranchermanager.docs.rancher.com/integrations-in-rancher/logging/custom-resource-configuration/flows-and-clusterflows)

## ClusterFlow (Active -- Cluster scope)
```
apiVersion: logging.banzaicloud.io/v1beta1
kind: ClusterFlow
metadata:
name: opensearch-fluentd-flow
  namespace: cattle-logging-system
spec:
  globalOutputRefs:
    - opensearch-fluentd
```
## ClusterOutput (Active -- Cluster Scope)
```
apiVersion: logging.banzaicloud.io/v1beta1
kind: ClusterOutput
metadata:
  name: opensearch-fluentd
  namespace: cattle-logging-system
spec:
  opensearch:
    host: 192.18.21.159
    index_name: rancher-logs
    password:
      valueFrom:
        secretKeyRef:
          key: user
          name: opensearch-fluentd-password
    port: 9200
    scheme: https
    ssl_verify: false
    suppress_type_name: true
    user: admin
```

## Flow (Example -- Namespace Scope)
```
apiVersion: logging.banzaicloud.io/v1beta1
kind: Flow
metadata:
  name: nginx-fluentd-flow
  namespace: flow-example
spec:
  localOutputRefs:
    - nginx-fluentd-output
  match:
    - select:
```
## Output (Example -- Namespace Scope)
```
apiVersion: logging.banzaicloud.io/v1beta1
kind: Output
metadata:
  name: nginx-fluentd-output
  namespace: flow-example
spec:
  opensearch:
    host: 192.18.21.159
    index_name: nginx-logs
    password:
      valueFrom:
        secretKeyRef:
          key: user
          name: nginx-opensearch-fluentd-password
    port: 9200
    scheme: https
    ssl_verify: false
    suppress_type_name: true
    user: admin
```
# Appendix C -- Training and References

## Rancher Documentation

**Description**: Official documentation for Rancher

<https://ranchermanager.docs.rancher.com/>

## RKE2 Documentation

**Description**: Official documentation for RKE2

<https://docs.rke2.io/>

## Harvester Documentation

**Description**: Official documentation for Harvester

<https://docs.harvesterhci.io>

## Longhorn Documentation

**Description**: Official documentation for Longhorn

<https://longhorn.io/docs>

## Neuvector Documentation

**Description**: Official documentation for Neuvector

<https://open-docs.neuvector.com/>

## Suse Events

**Description**: Free Online Events, Training and Webinars from SuSE on
Rancher, Neuvector, etc.

<https://www.suse.com/events/>

## Rancher Academy

**Description**: Collection of FREE Rancher, RKE2, and Kubernetes
related training

<https://www.rancher.academy/collections>

## Neuvector Youtube

**Description**: Official Youtube for Neuvector and Neuvector 101 video
that goes over basic

> capabilities and configuration of Neuvector

<https://www.youtube.com/@NeuVector/>

<https://www.youtube.com/watch?v=9ihaBr_QGzQ>

## Rancher Github

**Description**: Github repository for the latest releases of Rancher.
Submit bug reports, research

upgrades, etc

<https://github.com/rancher/rancher/>

## RKE2 Github

**Description**: Github repository with the latest releases of RKE2.
Cross reference with Rancher

Github releases to insure compatibility with Rancher. Submit bug
reports, research upgrades, etc

<https://github.com/rancher/rke2/>

## Neuvector Github

**Description**: Git hub repository with the latest release of
Neuvector. Submit bug reports,

research upgrades, etc

<https://github.com/neuvector/neuvector>

## Longhorn Github

**Description**: Github repository with the latest releases of Longhorn.
Submit bug reports, research

upgrades, etc

<https://github.com/longhorn/longhorn>

## Harvester Github

**Description**: Github repository with the latest release of Harvester.
Submit bug reports,

research upgrades, etc

<https://github.com/harvester/harvester>


## CIS Self Assessment

**Description**: CIS Self Assessment ling for CIS 1.6 and CIS 1.23 from
RKE2 Documentation

Can be used to verify Compliance in Neuvector as well for Kubernetes as
the sections should map

correctly to the Kubernetes category. For example CIS 1.6 section 1.2.10
directly maps to K.1.2.10

in Neuvector Compliance.

<https://docs.rke2.io/security/cis_self_assessment16>

<https://docs.rke2.io/security/cis_self_assessment123>
