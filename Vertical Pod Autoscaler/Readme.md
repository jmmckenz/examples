# The purpose of this script is to automatically create Vertical Pod Autoscaler (VPA) resources for all deployments, daemonsets, and statefulsets in all namespaces except system and rancher defaults. VPA's help in managing resource requests and limits for pods based on their actual usage.

# The script uses kubectl to fetch the resources and jq to parse the JSON output. It then constructs a VPA manifest in "Off" mode for each resource and applies it to the cluster. The VPA is named using the pattern "vpa-<kind>-<resource_name>" to ensure uniqueness.  

# VPA's set to "Off" mode means that it will not automatically update the resource requests and limits, but it will still provide recommendations based on observed usage.

# Once enough data has been collected, you can change the updateMode to "Recreate", "InPlaceOrRecreate", or "Initial" to allow VPA to automatically adjust the resource requests and limits for your pods. Please note that "InPlaceOrRecreate" mode is beta as of Kubernetes 1.33 and may not be supported in all environments. This feature graduated to GA GA as of Kubernetes 1.35 . Always test changes in a staging environment before applying them to production.

# Use of this script assumes previous installation of VPA (either from 
# vanilla kubernetes git repository or through the kubernetes hosted helm chart).