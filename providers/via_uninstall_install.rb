#
# Cookbook Name:: package-replace
# Provider:: via_uninstall_install
#
# Copyright 2018 Inviqa UK LTD
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
  package_replace_cache_reload(new_resource)
  package_replace_notification_definitions(new_resource)
  package_replace_service_definitions(new_resource)

  from_packages = new_resource.from_packages
  from_packages_string = from_packages.join(' ')

  to_packages = new_resource.to_packages
  to_packages_string = to_packages.join(' ')

  log "uninstall #{from_packages_string} -> install #{to_packages_string}" do
    action :log
  end

  package from_packages do
    action :remove
  end

  package to_packages do
    action :install
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
