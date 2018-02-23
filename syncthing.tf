provider "vultr" {
  api_key = "custom"
}

resource "vultr_ssh_key" "example" {
  name = "example created from terraform"

  # get the public key from a local file.
  #
  # create the example_rsa.pub file with:
  #
  #	ssh-keygen -t rsa -b 4096 -C 'terraform example' -f example_rsa -N ''
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "vultr_server" "example" {
  name = "example created from terraform"

  # set the region. 7 is Amsterdam.
  # get the list of regions with the command: vultr regions
  region_id = 7

  # set the plain. 29 is 768 MB RAM,15 GB SSD,1.00 TB BW.
  # get the list of plans with the command: vultr plans --region 7
  # 202 is 2GB RAM
  plan_id = 202

  # set the OS image. 179 is CoreOS Stable.
  # get the list of OSs with the command: vultr os
  # 245 is Fedora 26
  os_id = 245

  # enable IPv6.
  ipv6 = true

  # enable private networking.
  private_networking = true

  # enable one or more ssh keys on the root account.
  ssh_key_ids = ["${vultr_ssh_key.example.id}"]

  provisioner "file" {
    source      = "syncthing.service"
    destination = "/etc/systemd/system/syncthing.service"
  }

  # execute a command on the local machine.
  provisioner "local-exec" {
    command = "echo local-exec ${vultr_server.example.ipv4_address}"
  }

  # execute commands on the remote machine.
  provisioner "remote-exec" {
    inline = [
      # SECURITY WARNING: this is only possible on development machines
      "setenforce 0",

      # Open port 8205/TCP
      "firewall-cmd --add-port=8205/tcp",

      "wget https://github.com/syncthing/syncthing/releases/download/v0.14.45-rc.3/syncthing-linux-amd64-v0.14.45-rc.3.tar.gz",
      "tar -xf syncthing-linux-amd64-v0.14.45-rc.3.tar.gz",
      "mv syncthing-linux-amd64-v0.14.45-rc.3 /usr/local/syncthing",
      "chmod +x /usr/local/syncthing/syncthing",
      "systemctl daemon-reload",
      "systemctl enable syncthing.service",
      "systemctl start syncthing.service",
      "ip addr",
    ]
  }
}
