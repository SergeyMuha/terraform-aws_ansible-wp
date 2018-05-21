#! /bin/bash
sleep 180
mountpoint=$(cat /tmp/filesysid_for_mount.txt)
sudo mkdir -p  /var/www/html/wordpress
sudo chown -R ec2-user:ec2-user /var/www/html/wordpress
sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $mountpoint:/ /var/www/html/wordpress
#sudo /bin/su -c 'echo "$mountpoint:/ /var/www nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev,noresvport 0 0" >> /etc/fstab
echo "$mountpoint:/ /var/www/html/wordpress nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev,noresvport 0 0" | sudo tee -a  /etc/fstab
