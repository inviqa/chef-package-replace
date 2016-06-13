#
# Cookbook Name:: package_replace_test
# Recipe:: default
#
# Copyright 2016 Inviqa UK LTD
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

node['package_replace_test']['remove_packages'].each do |pkg|
  pkg_resource = package pkg do
    action :nothing
  end
  pkg_resource.run_action(:remove)
end

node['package_replace_test']['install_packages'].each do |pkg|
  pkg_resource = package pkg do
    action :nothing
  end
  pkg_resource.run_action(:install)
end

node['package_replace_test']['start_services'].each do |service_name|
  directory '/etc/init.d' do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end

  file "/etc/init.d/#{service_name}" do
    content 'exit 0'
    action :create
  end

  service_resource = service service_name do
    supports reload: true, restart: true, status: true
    action :nothing
  end
  service_resource.run_action(:start)
end
