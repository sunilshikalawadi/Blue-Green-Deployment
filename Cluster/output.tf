
output "cluster_id" {
  value = aws_eks_cluster.devopss.id
}

output "node_group_id" {
  value = aws_eks_node_group.devopss.id
}

output "vpc_id" {
  value = aws_vpc.devopss_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.devopss_subnet[*].id
}
