provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# -------------------------
# Networking
# -------------------------

resource "oci_core_vcn" "demo_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "demo-vcn"
}

resource "oci_core_internet_gateway" "demo_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.demo_vcn.id
  display_name   = "demo-igw"
  enabled        = true
}

resource "oci_core_route_table" "demo_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.demo_vcn.id
  display_name   = "demo-rt"

  route_rules {
    network_entity_id = oci_core_internet_gateway.demo_igw.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "demo_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.demo_vcn.id
  display_name   = "demo-sl"

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "demo_subnet" {
  cidr_block                 = "10.0.1.0/24"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.demo_vcn.id
  display_name               = "demo-subnet"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.demo_rt.id
  security_list_ids          = [oci_core_security_list.demo_sl.id]
}

# -------------------------
# Compute Instance
# -------------------------

resource "oci_core_instance" "demo_instance" {
  availability_domain = var.ad
  compartment_id      = var.compartment_ocid
  shape               = "VM.Standard.E5.Flex"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 4
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.demo_subnet.id
    assign_public_ip = true
    hostname_label   = "demo-vm"
  }

  display_name = "demo-instance"

  source_details {
    source_type = "image"
    source_id   = var.image_ocid
  }

  metadata = {
    ssh_authorized_keys = file("C:/Users/showu/.ssh/id_rsa.pub")
  }
}
