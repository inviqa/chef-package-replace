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

  context 'on centos, with a package replacement to replace the installed php' do
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
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.7', step_into: 'package_replace_via_plugin') do |node|
        node.set['package_replacements']['php'] = {
          enabled: true,
          from: 'replace_packages',
          to: 'replace_package_target',
          notify: {
            'service[php-fpm]' => 'restart',
            'service[apache2]' => 'reload'
          }
        }
        node.set['php']['replace_packages'] = replace_packages
        node.set['php']['replace_package_target'] = 'php56w-common'
      end.converge(described_recipe)
    end

    it 'will use the LWRP for replacing php' do
      expect(chef_run).to install_package_replace_via_plugin('php')
        .with(
          from_packages: replace_packages,
          to_package: 'php56w-common',
          notifications: {
            'service[php-fpm]' => 'restart',
            'service[apache2]' => 'reload'
          }
        )
    end

    it 'will include yum-webtatic to provide yum-plugin-replace' do
      expect(chef_run).to include_recipe('yum-webtatic')
    end

    it 'will install yum-plugin-replace' do
      expect(chef_run).to install_package('yum-plugin-replace')
    end

    it 'will not execute the yum reload ruby block' do
      expect(chef_run).to_not run_ruby_block('yum-cache-reload-after-replacement-php')
    end

    it 'will replace the installed package with the target package' do
      expect(chef_run).to run_execute("replace #{installed_package} -> php56w-common")
        .with_command("yum -y replace #{installed_package} --replace-with php56w-common")
    end

    it 'will not replace the packages that are not installed with the target package' do
      replace_packages.reject { |pkg| pkg == installed_package }.each do |pkg|
        expect(chef_run).to_not run_execute("yum -y replace #{pkg} --replace-with php56w-common")
      end
    end

    it 'will trigger a reload of the known installed packages cache' do
      expect(chef_run.execute("replace #{installed_package} -> php56w-common"))
        .to notify('ruby_block[yum-cache-reload-after-replacement-php]').to(:run).immediately
    end

    it 'will notify the php-fpm service to restart after replacing the php package' do
      expect(chef_run.execute("replace #{installed_package} -> php56w-common"))
        .to notify('service[php-fpm]').to :restart
    end

    it 'will notify the apache service to restart after replacing the php package' do
      expect(chef_run.execute("replace #{installed_package} -> php56w-common"))
        .to notify('service[apache2]').to :reload
    end
  end

  context 'on centos, with no package replacement necessary for the installed php' do
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

    before do
      replace_packages.each do |pkg|
        stub_command("rpm -q #{pkg}").and_return(false)
      end
    end

    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.7', step_into: 'package_replace_via_plugin') do |node|
        node.set['package_replacements']['php'] = {
          enabled: true,
          from: 'replace_packages',
          to: 'replace_package_target',
          notify: {
            'service[php-fpm]' => 'restart',
            'service[apache2]' => 'reload'
          }
        }
        node.set['php']['replace_packages'] = replace_packages
        node.set['php']['replace_package_target'] = 'php56w-common'
      end.converge(described_recipe)
    end

    it 'will use the LWRP for replacing php' do
      expect(chef_run).to install_package_replace_via_plugin('php')
        .with(
          from_packages: replace_packages,
          to_package: 'php56w-common',
          notifications: {
            'service[php-fpm]' => 'restart',
            'service[apache2]' => 'reload'
          }
        )
    end

    it 'will install yum-plugin-replace' do
      expect(chef_run).to install_package('yum-plugin-replace')
    end

    it 'will not execute the yum reload ruby block' do
      expect(chef_run).to_not run_ruby_block('yum-cache-reload-after-replacement-php')
    end

    it 'will not replace the packages that are not installed with the target package' do
      replace_packages.each do |pkg|
        expect(chef_run).to_not run_execute("replace #{pkg} -> php56w-common")
      end
    end
  end

  context 'on centos, with a configured package replacement disabled' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.7') do |node|
        node.set['package_replacements']['test'] = {
          enabled: false,
          from: 'replace_packages',
          to: 'replace_package_target'
        }
        node.set['test']['replace_packages'] = ['test']
        node.set['test']['replace_package_target'] = 'test2'
      end.converge(described_recipe)
    end

    it 'will not use the LWRP for replacing the test package' do
      expect(chef_run).to_not install_package_replace_via_plugin('test')
    end

    it 'will not install yum-plugin-replace' do
      expect(chef_run).to_not install_package('yum-plugin-replace')
    end

    it 'will not execute the yum reload ruby block' do
      expect(chef_run).to_not run_ruby_block('yum-cache-reload-after-replacement-test')
    end

    it 'will not attempt a package replacement when disabled' do
      expect(chef_run.find_resource('execute', 'replace test -> test2')).to be_nil
    end
  end

  context 'on centos, with yum shell replacement strategy' do
    before do
      stub_command('rpm -q test').and_return(true)
      stub_command('rpm -qa | egrep -i \'(test|test2)\'').and_return(true)
      stub_command('rpm -q test2').and_return(false)
    end

    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.7', step_into: 'package_replace_via_shell') do |node|
        node.set['package_replacements']['test'] = {
          enabled: true,
          strategy: 'yum_shell',
          from: 'replace_packages',
          to: 'replace_package_targets',
          notify: {
            'service[test]' => 'reload',
            'gem_package[test]' => 'reinstall'
          }
        }
        node.set['test']['replace_packages'] = %w(test test2)
        node.set['test']['replace_package_targets'] = %w(test3 test4)
      end.converge(described_recipe)
    end

    it 'will use the LWRP for replacing the test package' do
      expect(chef_run).to install_package_replace_via_shell('test')
        .with(
          from_packages: %w(test test2),
          to_packages: %w(test3 test4),
          notifications: {
            'service[test]' => 'reload',
            'gem_package[test]' => 'reinstall'
          }
        )
    end

    it 'will not execute the yum reload ruby block' do
      expect(chef_run).to_not run_ruby_block('yum-cache-reload-after-replacement-test')
    end

    it 'will replace the installed package with the target package' do
      expect(chef_run).to run_execute('replace test test2 -> test3 test4')
        .with_command('echo -e "remove test test2\ninstall test3 test4\nrun\n" | yum shell -y')
    end

    it 'will trigger a reload of the known installed packages cache' do
      expect(chef_run.execute('replace test test2 -> test3 test4'))
        .to notify('ruby_block[yum-cache-reload-after-replacement-test]').to(:run).immediately
    end

    it 'will notify the test service to reload after replacing the test package' do
      expect(chef_run.execute('replace test test2 -> test3 test4'))
        .to notify('service[test]').to(:reload).immediately
    end

    it 'will notify the test gem package to uninstall' do
      expect(chef_run.execute('replace test test2 -> test3 test4'))
        .to notify('gem_package[test]').to(:remove).immediately
    end

    it 'will notify the test gem package to install' do
      expect(chef_run.execute('replace test test2 -> test3 test4'))
        .to notify('gem_package[test]').to(:install).immediately
    end
  end
end
