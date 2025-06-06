#!/bin/bash
cd /root/bin/combustion/network
for each in `ls |grep -v yaml`
do
  MACTEST=`grep mac $each/* |awk -F= '{print $2}' |tail -1`
  if `ip addr show |grep -i $MACTEST > /dev/null`
  then
    CONFIGHOSTNAME=$each
    break
  fi
done

if [ "$CONFIGHOSTNAME" = "" ]
then
  exit 1
fi

cd $CONFIGHOSTNAME

for nic in `ls |grep -v bond`
do
  sed '/interface-name/d' $nic > /etc/NetworkManager/system-connections/$nic
  sed -i 's/cloned-mac/mac/g' /etc/NetworkManager/system-connections/$nic
done

cp *bond* /etc/NetworkManager/system-connections/
chmod 600 /etc/NetworkManager/system-connections/*

hostnamectl set-hostname $CONFIGHOSTNAME
