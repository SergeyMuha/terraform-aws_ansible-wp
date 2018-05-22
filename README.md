# terraform-aws_ansible-wp
You can use this configs to create aws infrastructure and deploy WP on private network with 3 nodes and 1 haproxy as balancer. DB and EFS will be created as database for wordpress and efs as docroot will be mounted

Requirements:
AWS-cli with configured AWS Access Key ID and AWS Secret Access Key -- use https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-linux.html 
https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html

HOW to :
Create aws key-pair

# aws ec2 create-key-pair --key-name terraformwp --query 'KeyMaterial' --output text > ~/.ssh/terraformwp.pem

# chmod 400 ~/.ssh/terraformwp.pem

# mkdir somedir

# git clone https://github.com/SergeyMuha/terraform-aws_ansible-wp.git

# cd terraform-aws_ansible-wp/terraform_aws_wp/

# terraform init

Deploy infrastructure 

# terraform apply -input=false -auto-approve   --- will output dns name for haproxy and bastion

SSH to bastion host to deploy wp with ansible

#ssh -i ~/.ssh/terraformwp.pem ec2-user@bastion

Export your keys with

# export AWS_ACCESS_KEY_ID=''
# export AWS_SECRET_ACCESS_KEY=''

Deploy Wordpress with

# ansible-playbook -i ec2.py main.yml --private-key ~/.ssh/terraformwp.pem

Check  haproxy dns name

To destroy infrastructure use 

# terraform destroy -input=false -auto-approve
