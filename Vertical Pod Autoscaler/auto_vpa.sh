#!/bin/bash

# The purpose of this script is to automatically create Vertical Pod 
# Autoscaler (VPA) resources for all deployments, daemonsets, and 
# statefulsets in all namespaces except system and rancher defaults. 
# VPA's help in managing resource requests and limits for pods based on 
# their actual usage.
# 
# The script uses kubectl to fetch the resources and jq to parse the JSON 
# output. It then constructs a VPA manifest in "Off" mode for each resource 
# and applies it to the cluster. The VPA is named using the pattern 
# "vpa-<kind>-<resource_name>" to ensure uniqueness.  
#
# VPA's set to "Off" mode means that it will not automatically update the 
# resource requests and limits, but it will still provide recommendations 
# based on observed usage.

# Once enough data has been collected, you can change the updateMode to 
# "Recreate", "InPlaceOrRecreate", or "Initial" to allow VPA to 
# automatically adjust the resource requests and limits for your pods.
# Please note that "InPlaceOrRecreate" mode is beta as of Kubernetes 1.33 
# and may not be supported in all environments. This feature graduated to GA 
# GA as of Kubernetes 1.35 . Always test changes in a staging environment 
# before applying them to production.
#
# Use of this script assumes previous installation of VPA (either from 
# vanilla kubernetes git repository or through the kubernetes hosted helm chart).

# Get all namespaces except system defaults to avoid breaking the cluster
echo "Getting namespaces:"

# Fixed the broken newline in the pattern string from your snippet
NAMESPACES=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -vE 'kube-system|kube-public|kube-node-lease|^cattle|^fleet|^local|cert-manager')

# Iterate through namespaces
for NS in $NAMESPACES
do
  # Get all deployments, daemonsets, and statefulsets
  mapfile -t RESOURCES < <(kubectl get deployments,daemonsets,statefulsets -n "$NS" -o json 2>/dev/null | jq -r '.items[] | "\(.kind) \(.metadata.name)"')

  # Iterate through resources by kind and name
  for RESOURCE in "${RESOURCES[@]}"
  do
    read -r KIND RESOURCENAME <<< "$RESOURCE"
    
    # Skip if variables are blank
    [[ -z "$KIND" || -z "$RESOURCENAME" ]] && continue

    # Build manifest
    VPA_YAML=$(cat <<EOF
apiVersion: "autoscaling.k8s.io/v1"
kind: VerticalPodAutoscaler
metadata:
  name: vpa-${KIND,,}-$RESOURCENAME
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: $KIND
    name: $RESOURCENAME
  updatePolicy:
    updateMode: "Off"
EOF
)
    # Install VPA
    echo "Installing vpa-${KIND,,}-$RESOURCENAME for $KIND $RESOURCENAME"

    kubectl apply -n "$NS" -f - <<< "$VPA_YAML"

    if [ $? -eq 0 ]; then
      echo "Successfully installed vpa-${KIND,,}-$RESOURCENAME for $KIND $RESOURCENAME"
    else
      echo "Failed to install vpa-${KIND,,}-$RESOURCENAME for $KIND $RESOURCENAME"
    fi
    
    # Optional create copy of the VPA manifest for reference (uncomment the
    # following 2 lines if you want to save the manifests to the CWD)

    #mkdir -p vpa-manifests/$NS 2>/dev/null
    #echo "$VPA_YAML" > vpa-manifests/$NS/vpa-${KIND,,}-$RESOURCENAME.yaml  
  done
done

