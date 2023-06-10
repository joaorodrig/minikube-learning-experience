IMAGE_NAME = "generic/ubuntu2204"

Vagrant.configure("2") do |config|
    config.ssh.insert_key = false
    config.vm.provider :libvirt do |libvirt|
        libvirt.memory = 2048
        libvirt.cpus = 2
        libvirt.default_prefix = "vagrant_"
        libvirt.driver = "kvm"
        libvirt.host = "localhost"
        libvirt.uri = "qemu:///system"
        libvirt.storage_pool_name = "vagrantpool" # Add your storage pool here
    end

    # NFS Host
    (1..1).each do |i|
        config.vm.define "minikube-nfs-#{i}" do |nfs_host|
            nfs_host.vm.box = IMAGE_NAME
            nfs_host.vm.network :private_network, :libvirt__network_name => "default"
            nfs_host.vm.hostname = "minikube-nfs-#{i}"
            nfs_host.vm.provision "ansible" do |ansible|
                ansible.playbook = "ansible/storage-server-playbook.yml"
                ansible.extra_vars = {
                    node_name: "minikube-nfs-#{i}"
                }
            end
        end
    end
end
