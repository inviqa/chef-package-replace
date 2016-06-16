#
# Cookbook Name:: package-replace
# Library:: provider_support
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

def package_replace_cache_reload(new_resource)
  ruby_block "yum-cache-reload-after-replacement-#{new_resource.type}" do
    block { Chef::Provider::Package::Yum::YumCache.instance.reload }
    action :nothing
    only_if { platform_family? 'rhel' }
  end
end

def package_replace_notification_definitions(new_resource)
  # Define notification targets to avoid errors upon notification
  if new_resource.notifications
    new_resource.notifications.reject { |target, _action| target.match(/^service\[/) }.each_pair do |target, _action|
      type = target.sub(/^([^\[]+)\[.*/, '\1')
      name = target.sub(/^.+\[(.+)\]$/, '\1')
      eval("#{type} '#{name}' do\naction :nothing\nend")
    end
  end
end

def package_replace_service_definitions(new_resource)
  # Define services to avoid errors upon notification
  if new_resource.notifications
    new_resource.notifications.select { |target, _action| target.match(/^service\[/) }.each_pair do |target, _action|
      service target.sub(/^service\[([^\]]+)\]$/, '\1') do
        supports reload: true, restart: true, status: true
      end
    end
  end
end
