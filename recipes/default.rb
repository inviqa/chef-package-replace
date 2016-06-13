#
# Cookbook Name:: package-replace
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

package 'yum-plugin-replace' do
  action :install
  only_if { platform_family? 'rhel' }
end

ruby_block 'yum-cache-reload-after-replacement' do
  block { Chef::Provider::Package::Yum::YumCache.instance.reload }
  action :nothing
  only_if { platform_family? 'rhel' }
end

replacements = node['package_replacements'].to_hash.keep_if do |_type, replacement|
  replacement['enabled'] == true || replacement['enabled'] == 'true'
end

replacements.each do |type, replacement|
  # Define services to avoid errors upon notification
  if replacement['notify']
    replacement['notify'].select{ |target, _action| target.match(/^service\[/) }.each_pair do |target, _action|
      service target.sub(/^service\[([^\]]+)\]$/, '\1') do
      end
    end
  end

  from_packages = node[type][replacement['from']]
  to_package = node[type][replacement['to']]

  from_packages.each do |package|
    execute "replace #{package} -> #{to_package}" do
      if replacement['strategy'] == 'yum_shell'
        command "echo -e \"remove #{package}\\ninstall #{to_package}\\nrun\\n\" | yum shell -y"
      else
        command "yum -y replace #{package} --replace-with #{to_package}"
      end
      only_if "rpm -q #{package}"
      notifies :run, 'ruby_block[yum-cache-reload-after-replacement]', :immediately
      if replacement['notify']
        replacement['notify'].each_pair do |target, action|
          notifies action, target
        end
      end
    end
  end
end
