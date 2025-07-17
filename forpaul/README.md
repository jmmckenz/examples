# Setup Environment
## Install Krew
[Install Krew](https://krew.sigs.k8s.io/docs/user-guide/setup/install/)

Install the resource-backup krew plugin
```shell
kubectl krew install resource-backup
```

Populate all kubeconfigs to ~/.kube
example:

```
    ~/.kube/devcluster-config
    ~/.kube/testcluster-config
    ~/.kube/prodcluster-config
```

# Get initial manifests from source
Update namespace list as needed. 
```shell
KUBECONFIG=~/.kube/development.yaml
cd ~
mkdir dev
cd dev

for namespace in "apps intranet cloud integrations microservices"
do
  mkdir $namespace
  cd $namespace
  kubectl resource-backup -n $namespace secret
  kubectl resource-backup -n $namespace deployment
  kubectl resource-backup -n $namespace service
  kubectl resource-backup -n $namespace ingress
  cd ..
done
```

# Create copies for other environments
```shell
cd ~
mkdir test
mkdir prod

cp -Rp dev/* test/
cp -Rp dev/* prod/
```

# Replace springboot env value in all manifests
```shell
for manifest in `find ./test -name "*.yaml"`
do
  sed -i 's/value: dev/value: test/g' $manifest
done

for manifest in `find ./prod -name "*.yaml"`
  sed -i 's/value: dev/value: prod/g' $manifest
done
```

# Manually review ingresses for host definitions (czardev vs czartest, etc) and review secrets to make sure they are specific to the current tier.  Will likely need to recreate the secrets (specifically tls secrets) for each individual environment.

# Manually check replicas: 0 for deployments

# Deployment
## TEST
```shell
KUBECONFIG=~/.kube/testing.yaml

for each in `find ./test -name "*.yaml"`
do
  kubectl apply -f $each
done
```

## PROD
```shell
KUBECONFIG=~/.kube/production.yaml
for each in `find ./prod -name "*.yaml"`
do
  kubectl apply -f $each
done
```

# Copy all the manifests into some form of source control, not that we have a source of truth for initial deployment for each environment.
