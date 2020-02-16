variable "tags" {
    description = "tags to add to the created resources"
    
    type = map
    default = {
        source      = "terraform"
        environment = "demo"
        costcenter  = "devops"
    }
}

variable "cluster_name" {
    description = "name of the EKS cluster"
    default     = "demo"
}