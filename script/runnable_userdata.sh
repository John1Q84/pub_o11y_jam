#!/bin/bash
set -e

echo 'get temporary token for metedata' && echo ''
TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
echo ''

echo '>> Get Region ....' && echo ''
export REGION=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN"  http://169.254.169.254/latest/dynamic/instance-identity/document/ | grep region | cut -d \" -f 4`
echo "export REGION=${REGION}" >> ~/.bash_profile 
echo $REGION && echo ''

echo '>> Get instance id ....' && echo ''
export INSTANCE_ID=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN"  http://169.254.169.254/latest/dynamic/instance-identity/document/ | grep instanceId | cut -d \" -f 4`
echo "export INSTANCE_ID=${INSTANCE_ID}" >> ~/.bash_profile 
echo $INSTANCE_ID && echo ''

# echo '>> Set AWS Credential for terraform ....'
# export AWS_ACCESS_KEY_ID=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN"  http://169.254.169.254/latest/meta-data/identity-credentials/ec2/security-credentials/ec2-instance/  |grep AccessKeyId | cut -d \" -f 4`
# export AWS_SECRET_ACCESS_KEY=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN"  http://169.254.169.254/latest/meta-data/identity-credentials/ec2/security-credentials/ec2-instance/  |grep SecretAccessKey | cut -d \" -f 4`
# echo "export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" >> ~/.bash_profile 
# echo "export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" >> ~/.bash_profile 
# echo $AWS_ACCESS_KEY_ID && echo ''

REPO="https://github.com/John1Q84/pub_o11y_jam.git"

# curl http://169.254.169.254/latest/dynamic/instance-identity/document | grep availabilityZone | cut -d \" -f 4 | sed 's/.$//'

main() {
    if [ $(id -u) -ne 0 ]; then
        echo "Run script as root!" >&2
        exit 1
    fi

    if [ ! -d "/opt/workspace" ] ; then
        mkdir /opt/workspace
    fi
    echo "/opt/workspace <- HOME_DIR"
    export HOME_DIR="/opt/workspace"
    cd $HOME_DIR
   
    sleep=0
    #while true; do
    #    install_tools &&
    #    git_init &&
    #    run_terraform &&
    #    kube_config &&
    #    break
    #done
    
    while true; do

        install_tools
        if [ $? -ne 0]; then
            echo "ERROR: install_tools step failed."
            return 1
        fi 

        git_init
        if [ $? -ne 0]; then
            echo "ERROR: git_init step failed."
            return 1
        fi 

        echo ">> terraform 1st phase: Provision VPC & EKS cluster" && echo " "
        run_terraform $HOME_DIR/pub_o11y_jam/terraform  
        if [ $? -ne 0]; then
            echo "ERROR: 1st phase of terraform failed."
            return 1
        fi

        echo ">> terraform 2nd phase: Provision ALB controller on the EKS cluster" && echo " "
        run_terraform $HOME_DIR/pub_o11y_jam/terraform/alb
        if [ $? -ne 0]; then
            echo "ERROR: 2nd phase of terraform failed."
            return 1
        fi

        kube_config
        if [ $? -ne 0]; then
            echo "ERROR: kube_config step failed."
            return 1
        fi     

        echo 'initializing complete !!'
        exit 0

        break
    done
}

install_tools(){
    echo '>> install tools step'
    # reset yum history
    sudo yum history new

    
    #   bash-completion: supports command name auto-completion for supported commands
    #   moreutils: a growing collection of the unix tools that nobody thought to write long ago when unix was young
    #   yum-utils: a prerequisite to install terraformn binary
    sudo yum -y install bash-completion moreutils yum-utils jq

    #   install latest terraform binary
    echo ">>> install terraform"
    sudo yum history new
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    sudo yum -y install terraform

    # Update awscli v1, just in case it's required
    # pip install --user --upgrade awscli

    # Install awscli v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm awscliv2.zip

    # Install kubectl v1.30
    curl -o /tmp/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.0/2024-05-12/bin/linux/amd64/kubectl


    sudo mv /tmp/kubectl /usr/local/bin
    chmod +x /usr/local/bin/kubectl

    # Install eksctl 
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin

    echo ' '
    echo '>> end of tool installation'

}

git_init(){
    echo '>> git init step'
    sudo yum history new
    sudo yum install git -y
    cd $HOME_DIR
    if [ -d $HOME_DIR/pub_o11y_jam ] ; then
        echo 'remove old git info'
        rm -rf $HOME_DIR/pub_o11y_jam
    fi
    git init pub_o11y_jam
    # git clone $REPO $HOME_DIR/pub_o11y_jam
    cd pub_o11y_jam
    git remote add -f origin $REPO
    git pull origin main
    echo ' '
    echo '>> end git init'
}

## old version
#run_terraform(){
#    echo '>> terraform init & apply step ...'    
#    cd $HOME_DIR/pub_o11y_jam
#    if [ -d $HOME_DIR/pub_o11y_jam/.terraform ] ; then  # `terraform init` command will generate $HOME_DIR/pub_o11y_jam/.terraform directory 
#        terraform plan && terraform apply -auto-approve > tfapply.log
#    else
#        terraform init -input=false && terraform plan && terraform apply -auto-approve  > tfapply.log
#    fi
#    export CLUSTER_NAME=`terraform output | grep eks_cluster_name | cut -d \" -f 2`
#    echo "export CLUSTER_NAME=$CLUSTER_NAME" >> ~/.bash_profile 
#    echo ' '
#    echo '>> running terraform complete!!'
#}

## new version : run_terraform "<PATH>"
run_terraform(){
    local dir=$1
    
    #echo ">> terraform 1st phase: Provision VPC & EKS cluster" && echo " "
    #cd $HOME_DIR/pub_o11y_jam/terraform && export WORKING_DIR=$(pwd)
    cd $dir && export WORKING_DIR=$(pwd)
    echo ">>> running terraform from $WORKING_DIR" 

    if [ -d $WORKING_DIR/.terraform ] ; then  # `terraform init` command will generate $HOME_DIR/pub_o11y_jam/terraform/.terraform directory
        terraform plan && terraform apply -auto-approve > tfapply.log 2>&1
    else
        terraform init -input=false && terraform plan && terraform apply -auto-approve  > tfapply.log 2>&1
    fi

    if [ $? -ne 0 ]; then
        echo "ERROR: Running terraform at $WORKING_DIR went something wrong. Check the log for details."
        echo "Last Log: " && echo ""
        tail -n 10 $WORKING_DIR/tfapply.log
        return 1
    fi

    export CLUSTER_NAME=$(terraform output | grep eks_cluster_name | cut -d \" -f 2)
    if [ -z "$CLUSTER_NAME" ]; then
        echo "ERROR: Fail to get EKS Cluster Name."
        return 1
    fi

    echo '>> running terraform at $WORKING_DIR complete!!'

}

kube_config(){
    echo ">> init kubectl configuration ..." && echo ""
    echo ">>> Global variable check ..." && echo ""
    if [ -z "$CLUSTER_NAME" ]; then
        echo "Error: Failed to get cluster name"
        return 1
    fi

    if [ -z "$REGION" ]; then
        echo "Error: Failed to get region"
        return 1
    fi

    echo ">>> CLUSTER_NAME: $CLUSTER_NAME / REGION: $REGION" && echo ""

    echo ">>> Get role ARN..." && echo ""
    ARN=$(aws iam get-role --role-name eks-jam-workstation-v2 --query Role.Arn --output text)
    if [ -z "$ARN" ]; then
        echo "Error: Failed to get role ARN"
        return 1
    fi
    echo "ARN: $ARN"

    echo ">>> Create access entry ..." && echo ""
    if ! aws eks create-access-entry --cluster-name eks-jam --principal-arn "$ARN"; then
        echo "Error: Failed to create access entry"
        return 1
    fi

    
    echo ">>> Associating EKSClusterAdminPolicy with access-entry ..." && echo ""
    
    if ! aws eks associate-access-policy \
        --cluster-name $CLUSTER_NAME \
        --principal-arn "$ARN" \
        --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
        --access-scope '{"type":"cluster"}'; then
        echo "Error: Failed to associate access policy"
        return 1
    fi

    echo ">>> Updating kubeconfig ..." && echo ""
    if ! aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"; then
        echo "Error: Failed to update kubeconfig"
        return 1
    fi

    if [ -d ~/.kube/ ] ; then  # `aws eks update-kubeconfig command generate '~/.kube' directory 
        echo 'kubectl config init complete'

        JAM_LABS_USER_ARN=$(aws iam list-roles --query "Roles[?starts_with(RoleName,'AWSLabsUser')].Arn" --output text)
        if [ -z "$JAM_LABS_USER_ARN" ]; then
            echo "Error: Failed to get JAM_LABS_USER_ARN"
            return 1
        fi
        echo "export JAM_LABS_USER_ARN=${JAM_LABS_USER_ARN}" >> ~/.bash_profile
        echo "JAM_LABS_USER_ARN: $JAM_LABS_USER_ARN" && echo ''

        echo '>> RBAC authorization'
        if ! eksctl create iamidentitymapping \
            --cluster "${CLUSTER_NAME}" \
            --arn "${JAM_LABS_USER_ARN}" \
            --username cluster-admin-jam-lab-user \
            --group system:masters \
            --region "${REGION}"; then
            echo "Error: Failed to create IAM identity mapping"
            return 1
        fi
        echo ''
    else
        echo 'Error: kubectl config initialization failed'
        return 1
    fi
    echo '>> Kube config initialization completed'
}
main
