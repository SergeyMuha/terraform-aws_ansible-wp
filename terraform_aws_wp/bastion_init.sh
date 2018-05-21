#! /bin/bash
sleep 50
chmod 400 ~/.ssh/aws_altoros_key.pem
cat /tmp/haproxy_workers_ip | xargs -I IP scp -o StrictHostKeyChecking=no -i ~/.ssh/aws_altoros_key.pem  /tmp/filesysid_for_mount.txt ec2-user@IP:/tmp/filesysid_for_mount.txt
while read host; do ssh -i ~/.ssh/aws_altoros_key.pem ec2-user@$host bash -s < /tmp/mount.sh & done < /tmp/haproxy_workers_ip
pip install --upgrade pip --user
pip install ansible --user
wget https://raw.github.com/ansible/ansible/devel/contrib/inventory/ec2.py
sudo chmod 755 ec2.py
wget https://raw.githubusercontent.com/ansible/ansible/devel/contrib/inventory/ec2.ini
sed -i 's/^destination_variable/#destination_variable/g' ec2.ini
sed -i 's/^vpc_destination_variable = ip_address/vpc_destination_variable = private_ip_address/g' ec2.ini
sudo yum install git -y
cd ~
