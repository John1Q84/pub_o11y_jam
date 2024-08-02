#!/bin/bash
set -e

echo 'get temporary token for metedata' && echo ''
TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
echo ''

export CLUSTER_NAME=eks-jam
echo "export CLUSTER_NAME=${CLUSTER_NAME}" >> ~/.bash_profile

echo '>> Get Region ....' && echo ''
export REGION=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN"  http://169.254.169.254/latest/dynamic/instance-identity/document/ | grep region | cut -d \" -f 4`
echo "export REGION=${REGION}" >> ~/.bash_profile 
echo $REGION && echo ''


kube_config

kube_config(){
    echo ">> init kubectl configuration ..." && echo ""
    echo ">>> Global variable check ..." && echo ""
    if [ -z "$CLUSTER_NAME" ]; then
        $CLUSTER_NAME=eks-jam
    fi

    if [ -z "$REGION" ]; then
        $REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN"  http://169.254.169.254/latest/dynamic/instance-identity/document/ | grep region | cut -d \" -f 4)
    fi

    echo ">>> CLUSTER_NAME: $CLUSTER_NAME / REGION: $REGION" && echo ""

    echo ">>> Get role ARN..." && echo ""
    ARN=$(aws iam get-role --role-name eks-jam-workstation-v2 --query Role.Arn --output text)
    if [ -z "$ARN" ]; then
        echo "Error: Failed to get role ARN"
    fi
    echo "ARN: $ARN"

    echo ">>> Create access entry ..." && echo ""
    if ! aws eks create-access-entry --cluster-name eks-jam --principal-arn "$ARN"; then
        echo "Error: Failed to create access entry"
    fi

    
    echo ">>> Associating EKSClusterAdminPolicy with access-entry ..." && echo ""
    
    if ! aws eks associate-access-policy \
        --cluster-name $CLUSTER_NAME \
        --principal-arn "$ARN" \
        --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
        --access-scope '{"type": "cluster"}'; then
        echo "Error: Failed to associate access policy"
    fi

    echo ">>> Updating kubeconfig ..." && echo ""
    if ! aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"; then
        echo "Error: Failed to update kubeconfig"
    fi

    if [ -d ~/.kube/ ] ; then  # `aws eks update-kubeconfig command generate '~/.kube' directory 
        echo 'kubectl config init complete'

        JAM_LABS_USER_ARN=$(aws iam list-roles --query "Roles[?starts_with(RoleName,'AWSLabsUser')].Arn" --output text)
        if [ -z "$JAM_LABS_USER_ARN" ]; then
            echo "Error: Failed to get JAM_LABS_USER_ARN"
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
        fi
        echo ''
    else
        echo 'Error: kubectl config initialization failed'
    fi
    echo '>> Kube config initialization completed'

    exit 0
}