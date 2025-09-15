

## install open-vmdk
```
zypper in -y open-vmdk
```

## install govc
Extract govc binary to /usr/local/bin.
Note: The "tar" command must run with root permissions.
```
curl -L -o - "https://github.com/vmware/govmomi/releases/latest/download/govc_$(uname -s)_$(uname -m).tar.gz" | tar -C /usr/local/bin -xvzf - govc
```

## Build OVA Compose

