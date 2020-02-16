terraform init
terraform apply -auto-approve
aws eks --region $AWS_DEFAULT_REGION update-kubeconfig --name demo

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml

kubectl get all --all-namespaces


aws ec2 describe-regions | \
  jq -r '.Regions[] | .RegionName' | \
  gxargs -l aws resourcegroupstaggingapi get-resources --region | \
  jq '.ResourceTagMappingList[] | .ResourceARN'


kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.28.0/deploy/static/mandatory.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/provider/aws/service-l4.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/provider/aws/patch-configmap-l4.yaml

