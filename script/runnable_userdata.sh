#!/bin/bash
set -e

echo 'get temporary token for metedata'
TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
echo ''

echo '>> Get Region ....'
export REGION=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN"  http://169.254.169.254/latest/dynamic/instance-identity/document/ | grep region | cut -d \" -f 4`
echo $REGION && echo ''

echo '>> Get instance id ....'
export INSTANCE_ID=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN"  http://169.254.169.254/latest/dynamic/instance-identity/document/ | grep instanceId | cut -d \" -f 4`
echo $INSTANCE_ID && echo ''

echo '>> Set AWS Credential for terraform ....'
export AWS_ACCESS_KDY_ID=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN"  http://169.254.169.254/latest/meta-data/identity-credentials/ec2/security-credentials/ec2-instance/  |grep AccessKeyId | cut -d \" -f 4`
export AWS_SECRET_ACCESS_KEY=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN"  http://169.254.169.254/latest/meta-data/identity-credentials/ec2/security-credentials/ec2-instance/  |grep SecretAccessKey | cut -d \" -f 4`
echo $INSTANCE_ID && echo ''

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
    echo "/opt/workspace <- home dir"
    export HOME_DIR="/opt/workspace"
    cd $HOME_DIR
   
    sleep=0
    while true; do
        install_tools &&
        git_init 
        # run_terraform &&
        break
    done
    echo 'initializing complete !!'
    exit 0

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
    pip install --user --upgrade awscli

    # Install awscli v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm awscliv2.zip

    # Install kubectl v1.24
    curl -o /tmp/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.24.10/2023-01-30/bin/linux/amd64/kubectl
    sudo mv /tmp/kubectl /usr/local/bin
    chmod +x /usr/local/bin/kubectl

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
    cd pub_o11y_jam
    git remote add -f origin $REPO
    git pull origin main
    echo '>> end git init'
}

run_terraform(){
    echo '>> terraform init & apply step'    
}


main

