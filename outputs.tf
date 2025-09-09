output "instance_public_ip" {
  description = "Public IP of the Compute instance"
  value       = oci_core_instance.demo_instance.public_ip
}