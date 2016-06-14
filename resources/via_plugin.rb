#
# Cookbook Name:: package-replace
# Resource:: via_plugin
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

resource_name :package_replace_via_plugin
provides :package_replace_via_plugin

property :type, String, name_property: true
property :from_packages, Array, default: []
property :to_package, String, default: ''
property :notifications, Hash, default: {}

actions [:install]
default_action :install
