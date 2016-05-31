#!/bin/bash

#setup ntp server
sudo service ntp restart

#setup network

sudo ifconfig br-eth0 down
sudo brctl delbr br-eth0
sudo brctl addbr br-eth0
sudo ifconfig br-eth0 10.20.0.1/24 up

sudo ifconfig br-eth1 down
sudo brctl delbr br-eth1
sudo brctl addbr br-eth1
sudo ifconfig br-eth1 172.16.0.1/24 up

sudo ifconfig br-dpdk down
sudo brctl delbr br-dpdk
sudo brctl addbr br-dpdk

#setup master

sudo virt-manager
sudo virsh destroy fuel-master
sudo rm -rf /var/lib/libvirt/images/fuel-master.img
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/fuel-master.img 200G

mkdir -p vms

iso=`pwd`/`ls *.iso`
sed  "s~ISO_FILE~$iso~g" fuel-master.xml > vms/fuel-master.xml

sudo virsh create vms/fuel-master.xml

#login fuel master
sleep 30
rm -rf ~/.ssh/known_hosts
sudo rm -rf ~/.putty
inprog=1
while [ $inprog -ne 0 ]
do
   echo "y\n" | plink -ssh -pw r00tme root@10.20.0.2 "echo y" >& /dev/null
   inprog=$?
   sleep 20
done

#cat astute.yaml | plink -ssh  -pw r00tme root@10.20.0.2 "dd of=/etc/fuel/astute.yaml"
#echo plink -ssh  -pw r00tme root@10.20.0.2 "pkill fuelmenu"

inprog=1
while [ $inprog -ne 0 ]
do
   echo "y\n" | plink -ssh -pw r00tme root@10.20.0.2 "grep 'Fuel node deployment complete' /var/log/puppet/bootstrap_admin_node.log "  >& /dev/null
   inprog=$?
   sleep 20
done

#setup slave
for i in {1..4}; do
    sudo virsh destroy fuel-slave-$i
    sudo rm -rf /var/lib/libvirt/images/fuel-slave-${i}.img
    sudo qemu-img create -f qcow2 /var/lib/libvirt/images/fuel-slave-${i}.img 200G
    sed "s/FUEL_SLAVE/fuel-slave-$i/g" fuel-slave.xml > vms/fuel-slave-${i}.xml
    sudo virsh create vms/fuel-slave-${i}.xml
done

#setup web browser
firefox https://10.20.0.2:8443 >& /dev/null &
