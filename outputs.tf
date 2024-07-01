output "jenkins_public_ip"{
    description = "Public IP of Jenkins instance"
    value = aws_instance.Jenkins.public_ip
}