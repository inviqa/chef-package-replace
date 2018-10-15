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

replacements = node['package_replacements'].to_hash.keep_if do |_type, replacement|
  replacement['enabled'] == true || replacement['enabled'] == 'true'
end

replacements.each do |type, replacement|
  if replacement['strategy'] == 'yum_shell'
    package_replace_via_shell type do
      from_packages node[type][replacement['from']]
      to_packages node[type][replacement['to']]
      notifications replacement['notify']
      action :install
    end
  elsif replacement['strategy'] == 'uninstall_install'
    package_replace_via_uninstall_install type do
      from_packages node[type][replacement['from']]
      to_packages node[type][replacement['to']]
      notifications replacement['notify']
      action :install
    end
  else
    include_recipe 'yum-webtatic'

    package_replace_via_plugin type do
      from_packages node[type][replacement['from']]
      to_package node[type][replacement['to']]
      notifications replacement['notify']
      action :install
    end
  end
end
