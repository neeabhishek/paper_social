output "webserver_ip" {
  value = aws_instance.webserver.public_ip
}
output "webserver_user" {
  value = var.user
}