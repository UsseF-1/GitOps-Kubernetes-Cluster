resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = "arn:aws:iam::569033310103:user/moaz-cicd"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_actions_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = "arn:aws:iam::569033310103:user/moaz-cicd"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_entry" "infra_engineer" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = "arn:aws:iam::569033310103:user/infrastructure-engineer"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "infra_engineer_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_eks_access_entry.infra_engineer.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
}
resource "aws_eks_access_entry" "yosef_team_leader" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = "arn:aws:iam::569033310103:user/yosef-team-leader"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "yosef_team_leader_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = "arn:aws:iam::569033310103:user/yosef-team-leader"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}