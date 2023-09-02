data "vkcs_networking_network" "extnet" {
 name = "ext-net"
}

resource "vkcs_networking_router" "router" {
 name = "router"
 admin_state_up = true
 external_network_id = data.vkcs_networking_network.extnet.id
}

resource "vkcs_networking_network" "wsr-network" {
   name = "wsr-network"
}

resource "vkcs_networking_subnet" "wsr-lb" {
   name = "wsr-lb"
   cidr = "192.168.199.0/24"
   network_id = vkcs_networking_network.wsr-network.id
}

resource "vkcs_networking_router_interface" "wsr-ip" {
 router_id = vkcs_networking_router.router.id
 subnet_id = vkcs_networking_subnet.wsr-lb.id
}

resource "vkcs_networking_secgroup" "wsr-secgroup" {
   name = "wsr-secgroup"
   description = "terraform security group"
}

resource "vkcs_networking_secgroup_rule" "secgroup_rule_1" {
   direction = "ingress"
   ethertype = "IPv4"
   port_range_max = 22
   port_range_min = 22
   protocol = "tcp"
   remote_ip_prefix = "0.0.0.0/0"
   security_group_id = vkcs_networking_secgroup.wsr-secgroup.id
   description = "secgroup_rule_1"
}

resource "vkcs_networking_secgroup_rule" "secgroup_rule_2" {
   direction = "ingress"
   ethertype = "IPv4"
   protocol = "icmp"
   security_group_id = vkcs_networking_secgroup.wsr-secgroup.id
}

resource "vkcs_compute_instance" "Web1" {
  name            = "Web1"
  flavor_id       = data.vkcs_compute_flavor.compute.id
  security_groups = ["wsr-secgroup"]
  image_id = data.vkcs_images_image.image.id
  availability_zone = "MS1"

  network {
    uuid = vkcs_networking_network.wsr-network.id
    fixed_ip_v4 = "192.168.199.110"
  }
 depends_on = [
    vkcs_networking_network.wsr-network,
    vkcs_networking_subnet.wsr-lb
  ]
}


resource "vkcs_compute_instance" "Web2" {
  name            = "Web2"
  flavor_id       = data.vkcs_compute_flavor.compute.id
  security_groups = ["wsr-secgroup"]
  image_id = data.vkcs_images_image.image.id
  availability_zone = "GZ1"

  network {
    uuid = vkcs_networking_network.wsr-network.id
    fixed_ip_v4 = "192.168.199.111"
  }
 depends_on = [
    vkcs_networking_network.wsr-network,
    vkcs_networking_subnet.wsr-lb
  ]
}



resource "vkcs_lb_loadbalancer" "loadbalancer" {
  name = "loadbalancer"
vip_subnet_id = "${vkcs_networking_subnet.wsr-lb.id}"
  tags = ["tag1"]
}

resource "vkcs_networking_floatingip" "fip" {
 pool = data.vkcs_networking_network.extnet.name
}

resource "vkcs_compute_floatingip_associate" "fip" {
 floating_ip = vkcs_networking_floatingip.fip.address
 instance_id = vkcs_lb_loadbalancer.loadbalancer.vip_port_id
}


resource "vkcs_lb_listener" "listener" {
  name = "listener"
  protocol = "HTTP"
  protocol_port = 80
  loadbalancer_id = "${vkcs_lb_loadbalancer.loadbalancer.id}"
}

resource "vkcs_lb_listener" "listener2" {
  name = "listener2"
  protocol = "HTTPS"
  protocol_port = 443
  loadbalancer_id = "${vkcs_lb_loadbalancer.loadbalancer.id}"
}


resource "vkcs_lb_pool" "pool" {
  name = "pool"
  protocol = "HTTP"
  lb_method = "ROUND_ROBIN"
  listener_id = "${vkcs_lb_listener.listener.id}"
}

resource "vkcs_lb_pool" "pool2" {
  name = "pool2"
  protocol = "HTTPS"
  lb_method = "ROUND_ROBIN"
  listener_id = "${vkcs_lb_listener.listener2.id}"
}

resource "vkcs_lb_member" "member_1" {
  address = "192.168.199.110"
  protocol_port = 80
  pool_id = "${vkcs_lb_pool.pool.id}"
  subnet_id = "${vkcs_networking_subnet.wsr-lb.id}"
  weight = 0
}

resource "vkcs_lb_member" "member_2" {
  address = "192.168.199.111"
  protocol_port = 80
  pool_id = "${vkcs_lb_pool.pool.id}"
  subnet_id = "${vkcs_networking_subnet.wsr-lb.id}"
}

resource "vkcs_lb_member" "member_11" {
  address = "192.168.199.110"
  protocol_port = 80
  pool_id = "${vkcs_lb_pool.pool2.id}"
  subnet_id = "${vkcs_networking_subnet.wsr-lb.id}"
  weight = 0
}

resource "vkcs_lb_member" "member_22" {
  address = "192.168.199.111"
  protocol_port = 80
  pool_id = "${vkcs_lb_pool.pool2.id}"
  subnet_id = "${vkcs_networking_subnet.wsr-lb.id}"
}

