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
  log "setting VPN URL to external IP address, #{node[:cloud][:public_ipv4]}"
  node.override[:ctt_ovpn][:vpn_url] = node[:cloud][:public_ipv4]
end

bash 'initialize,configure,start openvpn container' do
  code <<-EOF
  docker run --volumes-from #{node[:ctt_ovpn][:data_container]} --rm kylemanna/openvpn ovpn_genconfig -u udp://#{node[:ctt_ovpn][:vpn_url]}
  #/bin/expect -c "spawn docker run --volumes-from #{node[:ctt_ovpn][:data_container]} --rm -it kylemanna/openvpn ovpn_initpki nopass; expect -re \"RSA CA]:\"; send \"test\r\"; expect eof"
  #docker run --volumes-from #{node[:ctt_ovpn][:data_container]} -d -p 1194:1194/udp --cap-add=NET_ADMIN kylemanna/openvpn
  EOF
end
=begin
bash 'generate and retrieve vpn client certs' do
  code <<-EOF
  docker run --volumes-from #{node[:ctt_ovpn][:data_container]} --rm -it kylemanna/openvpn easyrsa build-client-full #{node[:ctt_ovpn][:client_name]} nopass
  docker run --volumes-from #{node[:ctt_ovpn][:data_container]} --rm kylemanna/openvpn ovpn_getclient #{node[:ctt_ovpn][:client_name]} > /home/ec2-user/#{node[:ctt_ovpn][:client_name]}.ovpn
  chown ec2-user. /home/ec2-user/#{node[:ctt_ovpn][:client_name]}.ovpn
  EOF
end
=end
