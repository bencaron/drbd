require 'resolv'

chefserver = Resolv.getaddress(`hostname`.chomp)
# temporarily point to myself
#chefserver = "192.168.1.109"

Vagrant.configure("2") do |globalconf|
  %w(primary secondary).each do |dekesse|
    vmname = dekesse
    file_to_disk = "./test/integration/sdb-#{dekesse}.vdi"

    globalconf.vm.define vmname do |config|
      config.vm.hostname = vmname
      if dekesse == "primary"
          config.vm.network :private_network, ip: "10.73.0.20"
      else
          config.vm.network :private_network, ip: "10.73.0.21"
      end
      config.vm.box = "rhel-6.5-x86_64"
      # This is our RHEL vagrant image, sorry :/ Should work with a centos box
      config.vm.box_url = "http://gustavo.lapresse.ca/vagrant/boxes/rhel-6.5-x86_64.box"

      config.vm.provider "virtualbox" do |vb|
        unless File.exist?(file_to_disk)
          vb.customize ['createhd', '--filename', file_to_disk, '--size', 10 * 1024]
          vb.customize ['storagectl', :id, '--name', 'SATA', '--add', 'sata', '--controller', 'IntelAHCI']
        end
        vb.customize ['storageattach', :id, '--storagectl', 'SATA', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', file_to_disk]
      end

      # Make the partition if it's not there already
      config.vm.provision :shell, inline: "(parted -l | grep /dev/sdb | grep unrecognised) && parted -s -a optimal /dev/sdb mklabel msdos  -- mkpart primary 1 -1 ; true"

      config.vm.provision :chef_client do |chef|
        chef.chef_server_url = "http://#{chefserver}:4545"
        chef.validation_key_path = "#{ENV['HOME']}/.chef/validation.pem"
        # This is a chef-zero node, no need to cleanup
        chef.delete_node = false
        chef.delete_client = false

        # Upload your roles before running!
        #chef.roles_path = 'test/integration/roles'
        chef.json = { }

        chef.run_list = [
          "recipe[drbd::default]",
          "role[drbd-pair-#{dekesse}]"
        ]
      end
    end
  end
end
