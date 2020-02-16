notes for building a kubernetes cluster on AWS with Terraform

terraform init
terraform apply -auto-approve
aws eks --region $AWS_DEFAULT_REGION update-kubeconfig --name demo

aws ec2 describe-regions | \
  jq -r '.Regions[] | .RegionName' | \
  gxargs -l aws resourcegroupstaggingapi get-resources --region | \
  jq '.ResourceTagMappingList[] | .ResourceARN'


kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.28.0/deploy/static/mandatory.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/provider/aws/service-l4.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/provider/aws/patch-configmap-l4.yaml


kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.13.0/cert-manager.yaml
kubectl apply -f letsencrypt.yaml


kubectl create deployment hello-node --image=gcr.io/hello-minikube-zero-install/hello-node
kubectl expose deployment hello-node --port=8080
kubectl apply -f hello-node-ingress.yaml 


# https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
kubectl apply -f dashboard-sa.yaml
kubectl apply -f dashboard-ingress.yaml

kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')

curl -v https://kubernetes-dashboard.aws.icteam.be




