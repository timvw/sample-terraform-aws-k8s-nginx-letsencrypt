resource "aws_key_pair" "ssh" {
  tags = var.tags
  key_name   = "ssh"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3sSvwyPpD0QdpcFl/El/ByxfODxIsDARI+5TlnI2fK2rMUWvF2PeUwpyjYCpVx3IDgOtUjNRoDRwteXs8mBT/DS+mA4A4e/KXRUynXr/GvRo3jWtZ6b1Z7WY2RBy8B9Dg3Bbv6naTVT1td+xm8kPFbb2w2Imj1oeUshyuPQ0cWugGgxbJ36s/7JlDeKItxWgQWQKOxZfihtaFDlQVs4fFNNxpXYSJQ507AZjHh1b+WGmtiCr9PF30xkt2f+46PWiSoq+Rlqm8BVdtQqoO9lWN2BjeHZckM+BLQbyAqIgDOC8edEg4u6OaRLSGgSzBnKi+sGbgl9OjFxg7MBtKvr5b tvwassen@PPC05739"
}

resource "aws_vpc" "main" {
    tags = merge(var.tags, { "kubernetes.io/cluster/${var.cluster_name}" = "shared" })
    cidr_block = "15.0.0.0/16"
    enable_dns_hostnames = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = var.tags
}

resource "aws_route" "r" {
  route_table_id            = aws_vpc.main.main_route_table_id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "k8s-net1" {
    tags = merge(var.tags, { 
      "kubernetes.io/cluster/${var.cluster_name}" = "shared" 
      "kubernetes.io/role/internal-elb" = "1"
    })
    vpc_id = aws_vpc.main.id
    cidr_block = "15.0.1.0/24"
    availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "k8s-net2" {
    tags = merge(var.tags, { 
      "kubernetes.io/cluster/${var.cluster_name}" = "shared" 
      "kubernetes.io/role/internal-elb" = "1"
    })
    vpc_id = aws_vpc.main.id
    cidr_block = "15.0.2.0/24"
    availability_zone = data.aws_availability_zones.available.names[1]
}

resource "aws_subnet" "k8s-net3" {
    tags = merge(var.tags, { 
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/elb" = "1"
    })
    vpc_id = aws_vpc.main.id
    cidr_block = "15.0.3.0/24"
    availability_zone = data.aws_availability_zones.available.names[2]
}

resource "aws_iam_role" "demo-cluster-role" {
  name = "demo-cluster-role"
  tags = var.tags

  assume_role_policy = jsonencode({
      Statement = [{
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "eks.amazonaws.com"
          }
      }]
  })
}

resource "aws_iam_role_policy_attachment" "demo-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.demo-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "demo-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.demo-cluster-role.name
}

resource "aws_eks_cluster" "demo" {
  name     = var.cluster_name
  tags     = var.tags
  role_arn = aws_iam_role.demo-cluster-role.arn

  vpc_config {
    subnet_ids         = [ aws_subnet.k8s-net1.id, aws_subnet.k8s-net2.id, aws_subnet.k8s-net3.id ] 
  }

  depends_on = [
    aws_iam_role_policy_attachment.demo-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.demo-cluster-AmazonEKSServicePolicy,
  ]
}

resource "aws_iam_role" "demo-node-role" {
  name = "demo-node-role"
  tags = var.tags

  assume_role_policy = jsonencode({
      Statement = [{
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
      }]
  })
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.demo-node-role.name
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.demo-node-role.name
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.demo-node-role.name
}

resource "aws_eks_node_group" "demo" {
  cluster_name    = aws_eks_cluster.demo.name
  tags     = var.tags
  node_group_name = "demo"
  node_role_arn   = aws_iam_role.demo-node-role.arn
  subnet_ids      = [ aws_subnet.k8s-net1.id, aws_subnet.k8s-net2.id ]
  instance_types  = [ "t3.medium" ]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  #remote_access {
  #  ec2_ssh_key = aws_key_pair.ssh.key_name
  #}

  depends_on = [
    aws_iam_role_policy_attachment.demo-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.demo-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.demo-node-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_eks_node_group" "public" {
  cluster_name    = aws_eks_cluster.demo.name
  tags     = var.tags
  node_group_name = "public"
  node_role_arn   = aws_iam_role.demo-node-role.arn
  subnet_ids      = [ aws_subnet.k8s-net3.id ]
  instance_types  = [ "t3.micro" ]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  #remote_access {
  #  ec2_ssh_key = aws_key_pair.ssh.key_name
  #}

  depends_on = [
    aws_iam_role_policy_attachment.demo-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.demo-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.demo-node-AmazonEC2ContainerRegistryReadOnly,
  ]
}