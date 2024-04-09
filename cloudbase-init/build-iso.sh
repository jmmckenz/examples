#!/bin/bash
#
# USAGE: buildiso.sh BASEDIR USERDATA OUTPUTISO

BASEDIR=$1
USERDATA=$2
OUTPUTISO=$3

if [ "$#" -ne "3" ]
then 
   echo "USAGE: buildiso.sh BASEDIR USERDATA OUTPUTISO"
   exit 3
fi


mkdir $BASEDIR
cd $BASEDIR
mkdir -p cd-image/openstack/latest
docker pull registry.suse.com/suse/vmdp/vmdp:latest
IMAGEID=`docker image ls |grep vmdp |awk '{print $3}'`
docker save $IMAGEID --output vmdp.tar
VMDPTAR=`tar tf vmdp.tar |grep -v layer.tar |grep tar`
tar xf vmdp.tar
tar xf $VMDPTAR
sudo mount disk/*.iso /mnt
cp -Rp /mnt/* cd-image/
cd cd-image/openstack/latest
cp $USERDATA .
python3 ~/bin/metadata.py
cd $BASEDIR
genisoimage -output $OUTPUTISO -volid config-2 -joliet -rock cd-image
