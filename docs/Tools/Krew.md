# Krew
## Krew Installation Instructions
### Pre-requisites
System must have git installed

[Install Krew](https://krew.sigs.k8s.io/docs/user-guide/setup/install/)

## Update Krew
```shell
kubectl krew update
```

## Install Krew Plugins
```shell
kubectl krew install {plugin_name}
```

### List of Plugins
[Full list of Krew plugins](https://krew.sigs.k8s.io/plugins/)

### Recommended Plugins
#### [node-shell](https://github.com/kvaps/kubectl-node-shell)
```
Start a root shell in the node's host OS running. Uses an alpine pod 
with nsenter for Linux nodes and a HostProcess pod with PowerShell for 
Windows nodes.
```

#### [get-all](https://github.com/corneliusweig/ketall)
```
Kubectl plugin to show really all kubernetes resources
```

#### [neat](https://github.com/itaysk/kubectl-neat)
```
Remove clutter from Kubernetes manifests to make them more readable.
```

#### [resource-backup](https://github.com/zak905/kubectl-resource-backup)
```
kubectl plugin that backs up Kubernetes objects (including CRDs) to
the local file system. Before saving any resource, the plugin does
some additional processing to remove:

* the status stanza if the object has any.
* the server generated fields from the object metadata.
* any field with a null value.

The plugin aims to make the saved objects look like the original
creation request. However, the plugin does not remove the fields that 
has a default value (unlike the neat plugin) because it's not possible 
to make a distinction between a value set by a creation/update request 
and a value set by a controller or a mutating admission webhook. 
```

#### [grep](https://github.com/guessi/kubectl-grep)
```
Filter Kubernetes resources by matching their names
```

#### [eksporter](https://github.com/Kyrremann/kubectl-eksporter)
```
A simple Ruby-script to export k8s resources, and removes a 
pre-defined set of fields for later import
```

#### [konfig](https://github.com/corneliusweig/konfig)
```
konfig helps to merge, split or import kubeconfig files
```

#### [cs](https://github.com/dodevops/kc)
```
cs is a kubectl plugin makes it easy to switch between multiple 
kubeconfig contexts or change the default namespace of the currently 
selected context.
```

#### [pv-migrate](https://github.com/utkuozdemir/pv-migrate)
```
pv-migrate is a CLI tool/kubectl plugin to easily migrate the contents of one Kubernetes PersistentVolumeClaim to another.
```

#### Note about yaml cleanup plugins

[neat](#neat), [resource-backup](#resource-backup), and [eksporter](#eksporter) all serve similar functions.  Of the three, I find [resource-backup](#resource-backup) to probably be the most useful for migration or replatforming, however you will have to run it on each resource type to get all the yamls in the namespace.  Any of these  could be used in a script with [get-all](#get-all) to build a comprehensive backup of resource manifests.

