provider "aws" {
  region = "ap-south-1"
}

# Use your existing VPC
data "aws_vpc" "existing_vpc" {
  id = "vpc-0fd0b7b32b2a42bce"  # Your existing VPC
}

resource "aws_subnet" "sunil_subnet" {  # Changed subnet name to include your name
  count = 2
  vpc_id                  = data.aws_vpc.existing_vpc.id
  cidr_block              = cidrsubnet(data.aws_vpc.existing_vpc.cidr_block, 8, count.index)
  availability_zone       = element(["ap-south-1a", "ap-south-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "sunil-subnet-${count.index}"  # Updated tag to include your name
  }
}

resource "aws_internet_gateway" "sunil_igw" {  # Updated IGW name
  vpc_id = data.aws_vpc.existing_vpc.id

  tags = {
    Name = "sunil-igw"  # Updated tag to include your name
  }
}

resource "aws_route_table" "sunil_route_table" {  # Updated route table name
  vpc_id = data.aws_vpc.existing_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sunil_igw.id  # Reference updated IGW
  }

  tags = {
    Name = "sunil-route-table"  # Updated tag to include your name
  }
}

resource "aws_route_table_association" "a" {
  count          = 2
  subnet_id      = aws_subnet.sunil_subnet[count.index].id  # Reference updated subnet
  route_table_id = aws_route_table.sunil_route_table.id  # Reference updated route table
}

resource "aws_security_group" "sunil_cluster_sg" {  # Updated cluster SG name
  vpc_id = data.aws_vpc.existing_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sunil-cluster-sg"  # Updated tag to include your name
  }
}

resource "aws_security_group" "sunil_node_sg" {  # Updated node SG name
  vpc_id = data.aws_vpc.existing_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sunil-node-sg"  # Updated tag to include your name
  }
}

resource "aws_eks_cluster" "sunil" {  # Updated EKS cluster name
  name     = "sunil-cluster"  # Updated cluster name to include your name
  role_arn = aws_iam_role.devopsshack_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.sunil_subnet[*].id  # Reference updated subnet
    security_group_ids = [aws_security_group.sunil_cluster_sg.id]  # Reference updated SG
  }
}

resource "aws_eks_node_group" "sunil" {  # Updated node group name
  cluster_name    = aws_eks_cluster.sunil.name  # Reference updated cluster
  node_group_name = "sunil-node-group"  # Updated node group name to include your name
  node_role_arn   = aws_iam_role.devopsshack_node_group_role.arn
  subnet_ids      = aws_subnet.sunil_subnet[*].id  # Reference updated subnet

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  instance_types = ["t2.large"]

  remote_access {
    ec2_ssh_key = "Mom"  # Your key pair name
    source_security_group_ids = [aws_security_group.sunil_node_sg.id]  # Reference updated SG
  }
}

resource "aws_iam_role" "devopsshack_cluster_role" {
  name = "devopsshack-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "devopsshack_cluster_role_policy" {
  role       = aws_iam_role.devopsshack_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "devopsshack_node_group_role" {
  name = "devopsshack-node-group-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "devopsshack_node_group_role_policy" {
  role       = aws_iam_role.devopsshack_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "devopsshack_node_group_cni_policy" {
  role       = aws_iam_role.devopsshack_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "devopsshack_node_group_registry_policy" {
  role       = aws_iam_role.devopsshack_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
