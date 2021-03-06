#
# Cookbook Name:: package-replace
# Provider:: via_plugin
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

use_inline_resources

action :install do
  include_recipe 'yum-webtatic'

  package 'yum-plugin-replace' do
    action :install
    only_if { platform_family? 'rhel' }
  end

  package_replace_cache_reload(new_resource)
  package_replace_notification_definitions(new_resource)
  package_replace_service_definitions(new_resource)

  to_package = new_resource.to_package

  new_resource.from_packages.each do |package|
    execute "replace #{package} -> #{to_package}" do
      command "yum -y replace #{package} --replace-with #{to_package}"
      only_if "rpm -q #{package}"
      notifies :run, "ruby_block[yum-cache-reload-after-replacement-#{new_resource.type}]", :immediately
      if new_resource.notifications
        new_resource.notifications.each_pair do |target, action|
          if action == 'reinstall'
            notifies :remove, target, :immediately
            notifies :install, target, :immediately
          else
            notifies action, target, :immediately
          end
        end
      end
    end
  end
end
