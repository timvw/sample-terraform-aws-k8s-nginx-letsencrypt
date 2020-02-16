terraform init
terraform apply -auto-approve
aws eks --region $AWS_DEFAULT_REGION update-kubeconfig --name k8s

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml

kubectl get all --all-namespaces


aws ec2 describe-regions | \
  jq -r '.Regions[] | .RegionName' | \
  gxargs -l aws resourcegroupstaggingapi get-resources --region | \
  jq '.ResourceTagMappingList[] | .ResourceARN'

