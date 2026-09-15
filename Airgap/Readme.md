# Airgap Documentation
https://docs.apps.rancher.io/howto-guides/mirror-with-artifactory
https://docs.harvesterhci.io/v1.8/airgap/#guest-cluster-images
https://documentation.suse.com/cloudnative/rke2/latest/en/install/airgap.html
https://documentation.suse.com/cloudnative/rke2/latest/en/install/airgap.html
https://docs.hauler.dev/docs/hauler-usage/login

# Hauler Examples
https://github.com/clemenko/rke_airgap_install
https://docs.apps.rancher.io/howto-guides/integrate-with-hauler

# Helm Chart Repos
https://charts.rancher.com/server-charts/prime
https://charts.jetstack.io
https://kube-vip.github.io/helm-charts
https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
https://charts.rancher.com/server-charts/prime/suse-observability

# Git based helm repos
https://github.com/rancher/partner-extensions
https://github.com/rancher/ui-plugin-charts
https://git.rancher.io/partner-charts

# Registry
registry.rancher.com

# Artifacts - text file with all rancher related images, including neuvector and longhorn
https://prime.ribs.rancher.io/rancher/v2.X.X/rancher-images.txt


# Options:
1) Use built-in artifactory proxy or replication to pull from registries, helm repos, and files/scripts
2) Use hauler to pull images to a tarball.  Move tarball to airgap.  Use hauler to launch a local server and push contents into Artifactory


# Point default registry for both Rancher and Harvester clusters to artifactory
May require rewrites or redirects of docker.io, quay.io, etc to artifactory uri using registries.yaml files
https://docs.rke2.io/install/private_registry
Configurable through Harvester UI - 'Advanced' -> 'Settings' -> 'containerd-registry'
Default registry can be configured in Rancher through settings.  Rewrites and redirects need to be setup in /etc/rancher/rke2/registries.yaml on from the command line and will require a restart of rke2.
  
Example registries.yaml
```
mirrors:
    docker.io:
    endpoint:
        - "https://artifactory.company.com"
    rewrite:
        "^rancher/(.*)": "mirrored-docker.io/rancher/$1"
configs:
    "artifactory.company.com":
    tls:
        insecure_skip_verify: 	# may be set to true to skip verifying the registry's certificate
        cert_file: 				# path to the cert file used in the registry
        key_file:  				# path to the key file used in the registry
        ca_file:   				# path to the ca file used in the registry#
```