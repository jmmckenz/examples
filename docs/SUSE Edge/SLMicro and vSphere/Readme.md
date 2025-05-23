<font size="16"> Table of Contents</font> 

- [1. Build cloud-init user-data](#1-build-cloud-init-user-data)
  - [1.1. user-data example](#11-user-data-example)
    - [1.1.1. Replace SSCREGCODEXXX with your SCC Registration Code for the SLMicro product.](#111-replace-sscregcodexxx-with-your-scc-registration-code-for-the-slmicro-product)
    - [1.1.2. Hashed passwords generation:](#112-hashed-passwords-generation)
  - [1.2. Convert to base64\\](#12-convert-to-base64)
- [2. Stage SLMicro VMDK for use in vSphere](#2-stage-slmicro-vmdk-for-use-in-vsphere)
  - [2.1. Download SLMicro VMDK](#21-download-slmicro-vmdk)
  - [2.2. Upload SLMicro VMDK to Datastore Staging Area](#22-upload-slmicro-vmdk-to-datastore-staging-area)
- [3. Build Initial VM for Templating](#3-build-initial-vm-for-templating)
  - [3.1. Import SLMicro VMDK to Imported VMDK Location on Datastore](#31-import-slmicro-vmdk-to-imported-vmdk-location-on-datastore)
  - [3.2. Create a VM from SLMicro VMDK](#32-create-a-vm-from-slmicro-vmdk)
    - [3.2.1. New Virtual Machine Creation Screen](#321-new-virtual-machine-creation-screen)
    - [3.2.2. Customize Hardware](#322-customize-hardware)
  - [3.3. Power on VM for initial build](#33-power-on-vm-for-initial-build)
    - [3.3.1. Launch Webconsole to monitor installation](#331-launch-webconsole-to-monitor-installation)
- [4. Convert SLMicro Initial VM to vSphere Template](#4-convert-slmicro-initial-vm-to-vsphere-template)


# 1. Build cloud-init user-data
## 1.1. user-data example
```yaml
#cloud-config
package_update: true
# disable root user
disable_root: true
runcmd:
# Disable root login over ssh, both password and key based
  - transactional-update --continue run sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /usr/etc/ssh/sshd_config
# Temporarily register template machine with scc to enable zypper repos
  - transactional-update --continue register --url https://scc.suse.com -r SCCREGCODEXXX
# Install system packages
  - transactional-update --continue --non-interactive pkg install jq net-tools ca-certificates cloud-init cloud-init-config-suse openssh-server open-vm-tools nfs-client
# Disable Auto update transaction-update.timer
  - transactional-update --continue run systemctl --now disable transactional-update.timer
# Set cgroupv1 hiearachy enabled
  - sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=0"/' /etc/default/grub
# Disable selinux
  - sed -i 's/selinux=1/selinux=0/' /etc/default/grub
# Enable ia32_emulation
  - sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="ia32_emulation=on /' /etc/default/grub
  - sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
# Potential Work Around for fsck issue
  - transactional-update --continue run dracut --regenerate-all -f -N
# Deregister template machine from scc
  - transactional-update --continue register -d --url https://scc.suse.com -r SCCREGCODEXXX
# Rebuild bootloader
  - transactional-update --continue run update-bootloader
# Reset cloud-init for next build
  - transactional-update --continue run cloud-init clean --logs

users:
# Add non-root user
  - name: harvest
    hashed_passwd: $6$e4RtND2Q2nDq1A4l$oeLJaqeWWIYnPHIxwcRTWrO6sqNIkmz3DroLmfxYSQTbeMq87UAL6uEQPB0BNKj.DNjVYd9Xa1xwcc9kVbBMI1
    lock_passwd: false
    shell: /bin/bash
# Add sudo entry for non-root user
    sudo: ALL=(ALL) NOPASSWD:ALL
# Add authorized keys
    ssh_authorized_keys:
      - ssh-rsa
        AAAAB3NzaC1yc2EAAAABJQAAAQEAkW7bd2iQBx8/A5pAbN207oWgcrV0lXgUHT2RZI/r/xbb9/ydLKCUBqmYhSKgBF80KJoWvE3cPeUDfThqo+qLlivc9vrTYZDMB+7wP/XGtA99jqFQsXDyC2gb8H/yKIRKu9eSrY9BHW9el80bpdxPID0YbxWYGJoxib5DO4mg3WtGIv9MeW4bvgoMj1ZhKMFrq2tYGv3P1MpuNgklwsGmUW+rIOVjhCEUz3KSr2+4EfcusOV6FD32SHkIgdeNy3C5MT1Oe6hk0bsUx/fZ9KS9YHX6b3LuIjkw1FuZBCByMgMWa4jO9QK/y76YMOFHOQtxhOszSuEkHtl6ijeejZYPtQ==
      - ssh-rsa
        AAAAB3NzaC1yc2EAAAADAQABAAABgQDZxAsYNJS266jPpWEsJwyibfZJN6FPNMHMxW9PlruOXJLrvdXc1wgo23d4c1BbaGiRoXW3xwd5zJwtr4dVB+QGtW1rCOYtHLGtvfIh6L5Y0SVrGOtDSVIpuwYtMnt4YBfZfBeDyJfnuvZ5E8CMNI1CekzfT7FgZnF1TQigOKgO8MUUS3HTNd3oly8D7w3QZLcjHufhFGojnZjEXfuT8tXqOaiCmlAzkdAmGczwTfXjZ3Q3KCEH20KTK31AxUP+80p75i2FE3QEMfHijXiuUbdEPTN8L2XSRe8nX7c3NZO5hWV+t9wLyfZgc5qHC5CS9fN1vGfLTpjQoaRoxKCS9dFJKVDg4huHcOz1go0YAQy6Ef+c7gkQv1ZV7VATTU9kVQWOy7+gztXnwoFXSg2qmn3JiJPVMDift2yozzpF+O4GpC9dgplBcugZT5Bg3TNPcfEBLGcNgIAC/bYma1z6+TDee0RDkWLg8JsCw554QCDI/B7Is1DZ/J4gTkmO1MNw3mM=

# set desired power_state after cloud-init finishes
power_state:
  mode: poweroff
  message: Powering Off for Templating
  timeout: 10
  condition: True
  ```
  
[user-data example](../code_examples/vsphere-cloud-init-userdata-example-final.txt)


### 1.1.1. Replace SSCREGCODEXXX with your SCC Registration Code for the SLMicro product.

### 1.1.2. Hashed passwords generation:

Generate random salt

```sh
openssl rand -hex 16
```

Generate hashed password using openssl

```sh
openssl passwd -6 -salt 7d651f2c15538f8c2f5542c4c05d061b password
```

## 1.2. Convert to base64\

```sh
cat user-data |base64
```

[user-data base64 example](../code_examples/vsphere-cloud-init-userdata-example-final-base64.txt)



# 2. Stage SLMicro VMDK for use in vSphere
## 2.1. Download SLMicro VMDK
The SLMicro images are avalable here:
[SLMicro Download Page](https://www.suse.com/download/sle-micro/)

![SLMicro Download Page](../images/SLMicroDownloadsPage.png)

You will need to login with you SCC Account to access the downloads.  

![SCC Login](../images/SCCLogin.png)

If prompted for two factor authentication, follow the instructions.  Once logged in, choose the appropriate vmdk image to download.

![Download VMDK](../images/Downloadvmdk.png)

## 2.2. Upload SLMicro VMDK to Datastore Staging Area
Navigate to Datastore Staging Area

![Navigate to Datastore Staging Area](../images/Navigate_to_datastore_staging.png)

Click "Upload Files" and select the appropriate vmdk to upload.

![Upload VMDK to Staging](../images/Upload_vmdk_to_staging.png)

Click "Open" (may vary depending on browser)

![Uploading VMDK](../images/Uploading_to_staging.png)

# 3. Build Initial VM for Templating
## 3.1. Import SLMicro VMDK to Imported VMDK Location on Datastore

Import the downloaded vmdk for use in building Template.  This step is necessary to make sure the VMDK is fully expanded and leaves the original VMDK in tact for future use.

Select the Uploaded vmdk in the Staging area

![Select Staged VMDK](../images/Select_staged_vmdk.png)

Click "Move To" to copy VMDK to Imported VMDK location and then click "OK"

![Copy VMDK to Imported VMDKs](../images/Copy_VMDK_from_staging_to_Imported_images.png)

```
Note:
The downloaded VMDK is sparse and may have some difficulty as is with Paravirtual SCSI controller if it is not expanded.  Moving the VMDK performs a copy of the source with the full volume size defined in the VMDK, and prevents the ParaVirtual SCSI controller issues when combined with choosing a compatible VM version later on. 
```

Wait for the image to complete copying.  

## 3.2. Create a VM from SLMicro VMDK

Click on "VMs and Templates"

![VMs and Templates1](../images/VMs_and_templates1.png)

Right Click the Cluster or Host and select "New Virtual Machine"

![Create New Virtual Machine1](../images/Select_new_virtual_machine.png)

### 3.2.1. New Virtual Machine Creation Screen

Select "Create a New Virtual Machine" and click "Next"

![Create a New Virtual Machine](../images/Create_new_virtual_machine_screen.png)

Select a Name and Folder/Host/Cluster and click "Next"

![Select a Name and Folder](../images/Select_a_name_and_folder_screen.png)

Select a Compute Resource and click "Next"

![Select a Compute Resource](../images/Select_a_compute_resource_screen.png)

Select the target Datastore and click "Next"

![Select Storage](../images/Select_storage_screen.png)

Select Compatibility with "ESX 6.7 and later" and click "Next"

```
Note:
We choose "ESX 6.7 and later" to insure compatibility with the generated vmdk.  Newer versions of the virtual machine compatibility can interfere with correctly assigning disks to the Paravirtual SCSI controller when we try to boot the VM for the first time.
```

![Select Compatibility](../images/Select_compatibility_screen.png)

On the Guest OS, Select "Guest OS Family" as "Linux", "Guest OS Version" as "SUSE Linux Enterprise 15 (64-bit)", and click "Next"

![Select Guest OS](../images/Select_guest_OS_screen.png)

### 3.2.2. Customize Hardware
Remove preconfigured HD

![Remove Preconfigured Hard Drive](../images/Remove_preconfigured_harddrive.png)

Add New Device "Existing Hard Disk" to VM

![Add New Device Existing Hard Disk](../images/Add_new_device_existing_hard_drive.png)

Select Datastore

![Select Datastore with Imported VMDK](../images/Select_datastore_that_contains_imported_vmdk.png)

Select SLMicro VMDK from Imported VMDK Location and click "OK"

![Select Imported VMDK for Existing Hard Disk](../images/Select_file_screen.png)

Add Required guestinfo parameters in Advanced Options

![Advanced Parameters Tab](../images/VS-AdvancedParameters1.png)

Set Attribute "guestinfo.userdata.encoding" with Value "base64" and click "Add"

![guestinfo.userdata.encoding](../images/guestinfo_userdata_encoding.png)

Set Attribute "guestinfo.userdata" with Value of the [base64 encoded userdata we created earlier](#convert-to-base64) and click "Add"

![guestinfo.userdata](../images/guestinfo_userdata.png)

Click "Next"

![Advanced Parameters Tab - Add guestinfo fields for cloud-init user-data](../images/VS-AdvancedParameters2.png)

Click "Finish"

![Finish VM Creation](../images/vm_creation_click_finish.png)

## 3.3. Power on VM for initial build

![Initial Power On](../images/Poweron_vmtemplate_for_initial_build.png)

### 3.3.1. Launch Webconsole to monitor installation

![Launch Webconsole](../images/launch_webconsole.png)

```
Note:
The VM should power down automatically based on the "powerstate" settings we configured in the userdata.
```

# 4. Convert SLMicro Initial VM to vSphere Template
Convert VM to Template either from the "Actions" pull down menu (shown), or by right clicking the name of the template and then choosing "Template" and clicking "Convert to Template"

![Convert to Template](../images/convert_to_template.png)

Confirm Template Conversion by clicking "Yes"

![Confirm Conver Template](../images/confirm_convert_to_template.png)

```
Note:
You should now be able to clone the template as needed for deployment of systems either directly from vSphere or through Rancher/CAPI/Turtles.  

For each use case, build separate templates and use different user-data for customization.  Simply comment out what is not needed in the user-data and build a base64 encoded version of the user-data to be populated in "guestinfo.userdata" attribute value when building your unique templates.
```

