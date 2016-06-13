#
# Cookbook Name:: package-replace
# Spec:: default
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

require 'spec_helper'

describe 'package-replace::default' do
  context 'When all attributes are default, on an unspecified platform' do
    cached(:chef_run) do
      runner = ChefSpec::SoloRunner.new
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end
  end

  context 'on centos, with no replacements' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.7').converge(described_recipe)
    end

    it 'will install yum-plugin-replace' do
      expect(chef_run).to install_package('yum-plugin-replace')
    end

    it 'will not execute the yum reload ruby block' do
      expect(chef_run).to_not run_ruby_block('yum-cache-reload-after-replacement')
    end
  end

  context 'on centos, with a php package replacement with a current version' do
    let(:replace_packages) do
      [
        'php-common',
        'php54-common',
        'php54w-common',
        'php54u-common',
        'php55-common',
        'php55w-common',
        'php55u-common'
      ]
    end

    let(:installed_package) { 'php54-common' }

    before do
      replace_packages.each do |pkg|
        stub_command("rpm -q #{pkg}").and_return(pkg == installed_package)
      end
    end

    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.7') do |node|
        node.set['package_replacements']['php'] = {
          enabled: true,
          from: 'replace_packages',
          to: 'replace_package_target',
          notify: {
            "service[php-fpm]" => "restart",
            "service[apache2]" => "reload"
          }
        }
        node.set['php']['replace_packages'] = replace_packages
        node.set['php']['replace_package_target'] = 'php56w-common'
      end.converge(described_recipe)
    end

    it 'will replace the installed package with the target package' do
      expect(chef_run).to run_execute("yum -y replace #{installed_package} --replace-with php56w-common")
    end

    it 'will not replace the packages that are not installed with the target package' do
      replace_packages.reject{ |pkg| pkg == installed_package }.each do |pkg|
        expect(chef_run).to_not run_execute("yum -y replace #{pkg} --replace-with php56w-common")
      end
    end

    it 'will trigger a reload of the known installed packages cache' do
      expect(chef_run.execute("yum -y replace #{installed_package} --replace-with php56w-common"))
        .to notify('ruby_block[yum-cache-reload-after-replacement]').to(:run).immediately
    end

    it 'will notify the php-fpm service to restart after replacing the php package' do
      expect(chef_run.execute("yum -y replace #{installed_package} --replace-with php56w-common"))
        .to notify('service[php-fpm]').to :restart
    end

    it 'will notify the apache service to restart after replacing the php package' do
      expect(chef_run.execute("yum -y replace #{installed_package} --replace-with php56w-common"))
        .to notify('service[apache2]').to :reload
    end
  end
end
