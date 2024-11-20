Should work with current EIB 1.1.0 container
registry.suse.com/edge/3.1/edge-image-builder:1.1.0 

Reason:
Currently, nmc does not handle bonds well. Please see https://github.com/suse-edge/nm-configurator/issues/66

Assumptions:
1) net.ifnames=1 for predictable network interface names is enabled in definition yaml
2) There is at least one NIC on the system that is NOT part of a bond.
3) Sample config is for harvester based install, adjust appropriately for bare metal or other HCI
4) Mileage May Vary --- This is a possible workaround, may not work for all use cases, just how I was able to get it to work.
5) Easier than the other workaround using run-once to force bond config after kexec.

Method:
1) Pre-populate nmconnection files for bond slaves in os-files/etc/NetworkManager/system-connections/
Sample bond98-enp4s0.nmconnection:
```
[connection]
id=bond98-enp4s0
type=ethernet
interface-name=enp4s0
master=bond98
slave-type=bond

[ethernet]

[bond-port]
```

2) For the network configuration file, use the NIC that is not used as part of a bond for identifying the system. Labeled below as
"ident-nic".  When specifying the bond definitions, **DO NOT** provide slave(port) information in the link-aggregation section(s). 
Sample elemental1.mclocal.yaml
```
routes:
  config:
  - destination: 0.0.0.0/0
    metric: 100
    next-hop-address: 192.168.50.1
    next-hop-interface: bond99
    table-id: 254
dns-resolver:
  config:
    server:
    - 10.0.0.94
interfaces:
- name: ident-nic
  type: ethernet
  identifier: mac-address
  state: down
  mac-address:
  ipv4:
    enabled: false
  ipv6:
    enabled: false
- name: bond99
  type: bond
  state: up
  ipv4:
    address:
      - ip: 192.168.50.241
        prefix-length: 24
    enabled: true
  ipv6:
    enabled: false
  link-aggregation:
    mode: balance-rr
    options:
      miimon: '140'
- name: bond98
  type: bond
  state: up
  ipv4:
    enabled: false
  ipv6:
    enabled: false
  link-aggregation:
    mode: balance-rr
    options:
      miimon: '140'
- name: bond98.101
  type: vlan
  state: up
  ipv4:
    enabled: true
```

3) Resulting build behavior:
   When booting to an image created with this workaround, nmc will be able to identify the system based on the ident-nic.  The bond(s) should get created, but will not have any slaves assigned.  The second run of nmc will **STILL** successfully identify the system and the setup process should complete, including the setting of hostname.  During combustion, the pre-defined nmconnection files should be copied over to /etc/NetworkManager/system-connections/.  Since we have no slaves for the bond, this should leave us in a networkless state on the system.
   Once the install media is ejected, reboot the system. When the system comes back up, NetworkManager should configure the bonds, and attach the slaves as defined in the nmconnection files provided in os-files to the corresponding interface-names.  If an nmconnection file has an interface-name configured that is not on the system, NetworkManager should ignore that connection and leave it down.  the "eth1" connection is the orphaned ident-nic.
```
elemental1:/usr/local # nmcli con show
NAME           UUID                                  TYPE      DEVICE
bond99         4a920503-4862-5505-80fd-4738d07f44c6  bond      bond99
lo             7d7b48ae-0abd-47bb-9f8b-10d6e13d4a38  loopback  lo
bond98.101     8a4142a3-57b2-5c0d-890d-e441e8e797b1  vlan      bond98.101
bond98         f652ecd9-9de3-5369-a224-19f427a043f5  bond      bond98
bond98-enp4s0  3e20c816-61a6-30e8-9cc7-cc3f2ef80ffb  ethernet  enp4s0
bond98-ens2    a0cd641d-a8fd-3e18-a631-54beb3747c38  ethernet  ens2
bond99-enp3s0  39da702a-74d8-382f-92b9-186d04f18f8d  ethernet  enp3s0
bond99-ens1    580f4c6e-912f-3d53-bbf8-5c4901da5d91  ethernet  ens1
bond98-enp5s0  04fb4043-57b2-393f-bf75-a737978f7b5c  ethernet  --
bond98-ens5    09cf4c88-d3ae-3140-b483-09bca10af247  ethernet  --
eth1           5edc425e-98f0-5dbc-8a65-6efaf2cf2ab7  ethernet  --
```
   
 
