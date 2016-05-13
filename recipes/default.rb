#
# Cookbook Name:: ctt_ovpn
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

include_recipe 'ctt_docker'

package 'expect'

docker_image 'busybox'

docker_image 'kylemanna/openvpn'

docker_container "#{node[:ctt_ovpn][:data_container]}" do
  repo 'busybox'
  volumes ['/etc/openvpn']
  action :run_if_missing
end

if node[:ctt_ovpn][:vpn_url] == nil
  node.override[:ctt_ovpn][:vpn_url] = node[:ec2][:public_ipv4]
end

bash "initialize and configure #{node[:ctt_ovpn][:data_container]} container" do
  code <<-EOF
  docker run --volumes-from #{node[:ctt_ovpn][:data_container]} --rm kylemanna/openvpn ovpn_genconfig -u udp://#{node[:ctt_ovpn][:vpn_url]}
  #/usr/bin/expect -c 'spawn docker run --volumes-from #{node[:ctt_ovpn][:data_container]} --rm -it kylemanna/openvpn ovpn_initpki; expect "Enter PEM pass phrase:"; send "qazwsx\r"; expect "Verifying - Enter PEM pass phrase:"; send "qazwsx\r"; expect "[Easy-RSA CA]:"; send "test\r"; expect "Enter pass phrase for /etc/openvpn/pki/private/ca.key:"; send "qazwsx\r"; expect eof'
  EOF
end
=begin
docker_container 'openvpn' do
  command "ovpn_genconfig -u udp://#{node[:ctt_ovpn][:ext_addr]}"
  repo 'kylemanna/openvpn'
  volumes_from "#{node[:ctt_ovpn][:data_container]}"
  autoremove true
  action :run
end
=end
