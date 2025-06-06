#!/bin/bash
#
# USAGE: buildiso.sh BASEDIR USERDATA OUTPUTISO

BASEDIR=$1
USERDATA=$2
OUTPUTISO=$3

# Verify all arguments have been passed to the script
if [ "$#" -ne "3" ]
then 
   echo "USAGE: buildiso.sh BASEDIR USERDATA OUTPUTISO"
   exit 3
fi

# Create BASEDIR
mkdir $BASEDIR 2> /dev/null
cd $BASEDIR

# Create cd-image base and openstack tree
mkdir -p cd-image/openstack/latest

# Pull the latest vmdp container from SUSE
docker pull registry.suse.com/suse/vmdp/vmdp:latest

# Dump the container to a tar file
IMAGEID=`docker image ls |grep vmdp |awk '{print $3}'`
docker save $IMAGEID --output vmdp.tar

# Extract the container tar file and the disk image inside the container
VMDPTAR=`tar tf vmdp.tar |grep -v layer.tar |grep tar`
tar xf vmdp.tar
tar xf $VMDPTAR

# Mount the iso and copy all contents to the cd-image base
sudo mount disk/*.iso /mnt
cp -Rp /mnt/* cd-image/

# Copy the user_data file to the openstack tree
cd cd-image/openstack/latest
cp $USERDATA .

# Generate the meta_data.json file required for cloudbase-init
python3 ~/bin/metadata.py

# Build the image using the installed tool.  If genisoimage does not exist comment out and uncomment the mkisofs line.
cd $BASEDIR
genisoimage -output $OUTPUTISO -volid config-2 -joliet -rock cd-image
# mkisofs -output $OUTPUTISO -volid config-2 -joliet -rock cd-image
