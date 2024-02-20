packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "packer-ubuntu-aws-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "us-east-1"
  ami_regions   = ["us-west-2", "us-east-1", "eu-central-1"]
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
  tags = {
    "Name"        = "MyUbuntuImage"
    "Environment" = "Production"
    "OS_Version"  = "Ubuntu 22.04"
    "Release"     = "Latest"
    "Created-by"  = "Packer"
  }
}

source "azure-arm" "ubuntu" {
  client_id                         = "XXXX"
  client_secret                     = "XXXX"
  managed_image_resource_group_name = "packer_images" # You must create a resource group to save the images to
  managed_image_name                = "packer-ubuntu-azure-{{timestamp}}"
  subscription_id                   = "98d4d670-4074-4235-90be-149b4d17345d"
  tenant_id                         = "8b17620c-21bb-4b56-b7bd-7e6d51fd672e"

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "UbuntuServer"
  image_sku       = "16.04-LTS"

  azure_tags = {
    Created-by = "Packer"
    OS_Version = "Ubuntu 16.04"
    Release    = "Latest"
  }

  location = "East US"
  vm_size  = "Standard_A2"
}

build {
  name = "ubuntu"
  sources = [
    "source.amazon-ebs.ubuntu",
    "source.azure-arm.ubuntu", 
  ]

  provisioner "shell" {
    inline = [
      "echo Installing Updates",
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y nginx"
    ]
  }

  provisioner "shell" {
    only = ["source.amazon-ebs.ubuntu"]
    inline = ["sudo apt-get install awscli"]
  }

  provisioner "shell" {
    only = ["source.azure-arm.ubuntu"]
    inline = ["sudo apt-get install azure-cli"]
  }

  post-processor "manifest" {}

}