# -*- mode: ruby -*-
# vi: set ft=ruby :

DOMAIN="vm.springlabs.dev"
MEMORY=2048
SUBNET="192.168.54"
INSTANCES=3
COOKIE="#{ENV['COOKIE']}"

$update_system = <<EOF
sudo yum update -y
EOF

$rabbitmq = <<EOF
echo "#{COOKIE}"
sudo rm -rf /etc/yum.repos.d/rabbitmq-erlang.repo
sudo tee -a /etc/yum.repos.d/rabbitmq-erlang.repo <<'EOL'>/dev/null
[rabbitmq_erlang]
name=rabbitmq_erlang
baseurl=https://packagecloud.io/rabbitmq/erlang/el/7/$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/erlang/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[rabbitmq_erlang-source]
name=rabbitmq_erlang-source
baseurl=https://packagecloud.io/rabbitmq/erlang/el/7/SRPMS
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/erlang/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOL

sudo rm -rf /etc/yum.repos.d/rabbitmq-server.repo
sudo tee -a /etc/yum.repos.d/rabbitmq-server.repo <<'EOL'>/dev/null
[rabbitmq_rabbitmq-server]
name=rabbitmq_rabbitmq-server
baseurl=https://packagecloud.io/rabbitmq/rabbitmq-server/el/7/$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[rabbitmq_rabbitmq-server-source]
name=rabbitmq_rabbitmq-server-source
baseurl=https://packagecloud.io/rabbitmq/rabbitmq-server/el/7/SRPMS
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOL


sudo yum makecache
sudo yum -y install erlang rabbitmq-server
sudo systemctl enable rabbitmq-server
sudo echo "#{COOKIE}" > /var/lib/rabbitmq/.erlang.cookie
sudo chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
sudo chmod 0600 /var/lib/rabbitmq/.erlang.cookie
sudo systemctl start rabbitmq-server
sudo rabbitmq-plugins enable rabbitmq_management
sudo rabbitmqctl change_password guest alongpasswordofsomekindhere

sudo tee -a /etc/hosts <<EOL>/dev/null
192.168.54.22 rabbitmq0 rabbitmq0.dev.springlabs.dev
192.168.54.23 rabbitmq1 rabbitmq1.dev.springlabs.dev
192.168.54.24 rabbitmq2 rabbitmq2.dev.springlabs.dev
EOL

EOF

Vagrant.configure("2") do |config|
 if Vagrant.has_plugin?("vagrant-vbguest") then
   config.vbguest.auto_update = true
 end

 config.vm.box = "bento/centos-7.6"
 config.vm.box_version = "201812.27.0"
 if Vagrant.has_plugin?("vagrant-cachier")
   config.cache.scope = :box
 end

 INSTANCES.times do |i|

   config.vm.define "rabbit#{i}".to_sym do |vmconfig|
     vmconfig.vm.network 'forwarded_port', guest: 15672, host: 15672, host_ip: "192.168.1.17", protocol: "tcp", auto_correct: true
     vmconfig.vm.synced_folder ".", "/vagrant"
     # vmconfig.vm.box = "bento/centos-7.6"
     # vmconfig.vm.box_version = "201812.27.0"
     vmconfig.vm.network :private_network, ip: "#{SUBNET}.%d" % (22 + i)
     vmconfig.vm.hostname = "rabbitmq%d.#{DOMAIN}" % i
     vmconfig.vm.provider :virtualbox do |vb|
         vb.customize ["modifyvm", :id, "--memory", MEMORY ]
     end
     vmconfig.vm.provision :shell, :inline => $update_system
     vmconfig.vm.provision :shell, :inline => $rabbitmq
     vmconfig.vm.provision :shell, :inline => "echo #{COOKIE}"
   end
 end

 config.vm.define :manager do |vmconfig|
   vmconfig.vm.synced_folder ".", "/vagrant"
   # vmconfig.vm.box = "bento/centos-7.6"
   # vmconfig.vm.box_version = "201812.27.0"
   vmconfig.vm.network :private_network, ip: "#{SUBNET}.20"
   vmconfig.vm.hostname = "manager.#{DOMAIN}"
   vmconfig.vm.provider :virtualbox do |vb|
       vb.customize ["modifyvm", :id, "--memory", MEMORY ]
   end
   vmconfig.vm.provision :shell, :inline => $update_system
vmconfig.vm.provision :shell, :inline => $rabbitmq
 end
end
