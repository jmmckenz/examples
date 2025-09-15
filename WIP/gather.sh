edge-image-builder:~ # cat gather.sh
#!/bin/bash -xxxxxxxxxx
CONFIG_DIR=~/kubeconfigs
CLUSTER_LIST=~/clusters.txt
DATA_DIR=~/gather

for local in `cat $CLUSTER_LIST`
do
  KUBE_API_URL=$(grep server $CONFIG_DIR/$local.yaml |awk -F\" '{print $2}' |sed 's/k8s\/clusters\/local/v3/')
  KUBE_TOKEN=$(grep token $CONFIG_DIR/$local.yaml |awk -F\" '{print $2}')
  CLUSTERS=$(curl -s -k -H "Authorization: Bearer $KUBE_TOKEN" "$KUBE_API_URL/clusters" | jq -r '.data[].id')

  mkdir -p $CONFIG_DIR/$local

  export KUBECONFIG=$CONFIG_DIR/$local.yaml

  for CLUSTER_ID in $CLUSTERS
  do
    CONFIG_JSON=$(curl -k -X POST -H "Authorization: Bearer $KUBE_TOKEN" \
         "$KUBE_API_URL/clusters/$CLUSTER_ID?action=generateKubeconfig")
    CONFIG_YAML=$(echo "$CONFIG_JSON" | jq -r '.config')
    CLUSTER_NAME=$(kubectl get clusters.management.cattle.io $CLUSTER_ID --no-headers=true -o custom-columns=NAME:.spec.displayName)
    echo "$CONFIG_YAML" > "$CONFIG_DIR/$local/$CLUSTER_NAME.yaml"
  done

  for cluster in `kubectl get clusters.management.cattle.io --no-headers=true -o custom-columns=NAME:.spec.displayName`
  do
    export KUBECONFIG=$CONFIG_DIR/$local/$cluster.yaml
    mkdir -p $DATA_DIR/$local/$cluster
    cd $DATA_DIR/$local/$cluster
    for namespace in `kubectl get namespace --no-headers=true |awk '{print $1}'`
    do
      k8sviz.sh -n $namespace -t png -o $namespace.png -k $CONFIG_DIR/$local/$cluster.yaml
    done
  done
done
