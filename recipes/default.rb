#
# Author:: Matt Ray <matt@opscode.com>
# Cookbook Name:: drbd
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
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

#prime the search to avoid 2 masters
node.save unless Chef::Config[:solo]


# Ok, why does the docs say "redhat" but my systems says rhel??
if node.platform_family?("centos", "redhat", "rhel", "fedora")
  utilspkg = "drbd#{node['drbd']['version'].sub('.','')}-utils"
  kmodpkg  = "kmod-drbd#{node['drbd']['version'].sub('.','')}"

  yum_repository 'elrepo' do
    mirrorlist 'http://elrepo.org/mirrors-elrepo.el6'
    description 'ELRepo.org Yum Repository'
    enabled true
    gpgcheck true
    gpgkey 'http://www.elrepo.org/RPM-GPG-KEY-elrepo.org'
  end
elsif node.platform_family?("debian", "ubuntu")
  utilspkg = "drbd8-utils"
  kmodpkg  = "drbd8-module"
elsif node.platform_family?("suse")
  # ugly hack: suse has only one package. I don't want to have seperate logic for it. So...
  utilspkg = "drbd"
  kmodpkg  = "drbd"
else
  log("Your platform (#{node['platform_family']})is not explicitely supported by this cookbook, sorry"){ level :fatal}
end

log "Installing DRBD from packages #{utilspkg} and #{kmodpkg}"

[kmodpkg,utilspkg].each do |pkg|
  log("Install #{pkg}")
  package pkg do
    action :install
  end
end

service "drbd" do
  supports(
    :restart => true,
    :status => true
  )
  action :nothing
end
