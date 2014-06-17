#
# Author:: Matt Ray <matt@opscode.com>
# Cookbook Name:: drbd
# Recipe:: pair
#
# Copyright 2011, Opscode, Inc
# Copyright 2014, La Presse
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'mixlib/shellout'

include_recipe "drbd::default"

resource = "pair"

if node['drbd']['remote_host'].nil? || node['drbd']['remote_ip'].nil?
  Chef::Application.fatal! "You must define a ['drbd']['remote_host'] or a ['drbd']['remote_ip'] to use the drbd::pair recipe."
end

remote = search(:node, "name:#{node['drbd']['remote_host']}")[0]


## FIXME need to adjust, stuff is probably missing
# http://www.drbd.org/users-guide/s-reconfigure.html
template "/etc/drbd.d/#{resource}.res" do
  source "res.erb"
  variables(
    :resource => resource,
    :remote_ip => node['drbd']['remote_ip'] || remote.ipaddress,
    :internal_ip => node['drbd']['internal_ip'] || node['ipaddress']
    )
  owner "root"
  group "root"
  action :create
end

template "/etc/drbd.d/global_common.conf" do
  source "global_common.conf.erb"
  variables(
    :usage_count => node['drbd']['usage_count'],
    :protocol => node['drbd']['protocol'],
    :rate => node['drbd']['sync_rate']
  )
  owner "root"
  group "root"
  action :create
end

# first pass only, initialize drbd
execute "drbdadm-create-#{resource}" do
  command "drbdadm create-md #{resource}"
  subscribes :run, "template[/etc/drbd.d/#{resource}.res]"
  notifies :run, "execute[drbdadm-up-#{resource}]"
  not_if do
    cmd = Mixlib::ShellOut.new("drbdadm role #{resource}")
    st = cmd.run_command.status
    Chef::Log.info "Checking if for create-md ; not if : >drbdadm role #{resource}<: status = #{st}"
    st == 0
  end
end

# up the resource, but only if it's not
execute "drbdadm-up-#{resource}" do
  command "drbdadm up #{resource}"
  not_if "drbdadm cstate pair"
  notifies :run, "execute[drbdadm-set-primary-#{resource}]"
end

#claim primary based off of node['drbd']['master']
execute "drbdadm-set-primary-#{resource}" do
  command "drbdadm primary --force #{resource}"
  not_if  {
    [
      "mount | grep #{node['drbd']['dev']}"
    ].each do |shell|
      cmd = Mixlib::ShellOut.new(shell)
      st = cmd.run_command.status
      Chef::Log.info "Checking if we drbdadm set primary; not if : >#{shell}<: status = #{st}"
      break true if st == 0
    end
    false
  }
  only_if { node['drbd']['master'] && !node['drbd']['configured'] }
  notifies :run, "execute[mkfs-#{resource}]"
end

#You may now create a filesystem on the device, use it as a raw block device
execute "mkfs-#{resource}" do
  command "mkfs -t #{node['drbd']['fs_type']} #{node['drbd']['dev']}"
  not_if  {
    [
      "mount | grep #{node['drbd']['dev']}",
      "blkid | grep #{node['drbd']['dev']} | grep #{node['drbd']['fs_type']}",
      "drbdadm role #{resource} | grep Secondary",
    ].each do |shell|
      cmd = Mixlib::ShellOut.new(shell)
      st = cmd.run_command.status
      Chef::Log.info "Checking if we should mkfs: >#{shell}<: status = #{st}"
      break true if st == 0
    end
    false
  }
  only_if { node['drbd']['master'] && !node['drbd']['configured'] }
  action :run
  notifies :write, "log[ran mkfs]", :immediately
  notifies :run, "ruby_block[set drbd configured flag]"
  notifies :mount, "mount[#{node['drbd']['mount']}]"
end

log "ran mkfs" do
  message "Device #{node['drbd']['dev']} is now formated as #{node['drbd']['fs_type']}"
  level  :info
  action :nothing
end

# prepare our mount point on both primary and secondary (ready for failover)
directory node['drbd']['mount'] do
  action :create
end

# Mount it only on the primary
# FIXME what to do if our primary is now manually/failoverly turned into a secondary?
mount node['drbd']['mount'] do
  device node['drbd']['dev']
  fstype node['drbd']['fs_type']
  only_if { node['drbd']['master'] && node['drbd']['configured'] }
  action :mount
end

# If we are done, someone will notify us
ruby_block "set drbd configured flag" do
  block do
    node.set['drbd']['configured'] = true
    Chef::Log.info "We are now configured"
  end
  action :nothing
end
