Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  config.vm.define "server" do |server|
    server.vm.hostname = "server.loc"
    server.vm.network "private_network", ip: "192.168.56.10"
    server.vm.provision "shell", inline: <<-SHELL
      apt-get update
      sudo sed -i 's/#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
      sudo sed -i 's/#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
      sudo sed -i 's|^Include /etc/ssh/sshd_config.d/\*.conf|#Include /etc/ssh/sshd_config.d/*.conf|' /etc/ssh/sshd_config
      sudo systemctl restart sshd
    SHELL
  end

  config.vm.define "client" do |client|
    client.vm.hostname = "client.loc"
    client.vm.network "private_network", ip: "192.168.56.20"
    client.vm.provision "shell", inline: <<-SHELL
      apt-get update
    SHELL
  end
end
