require 'spec_helper'

describe 'package-replace::default' do
  it 'does not have php-common installed' do
    expect(package('php-common')).to_not be_installed
  end

  it 'does not have php-fpm installed' do
    expect(package('php-fpm')).to_not be_installed
  end

  it 'has php56w-common installed' do
    expect(package('php56w-common')).to be_installed
  end

  it 'has php56w-fpm installed' do
    expect(package('php56w-fpm')).to be_installed
  end

  if os[:family] == 'redhat' && os[:release] == '6.7'
    it 'does not have mysql-libs installed' do
      expect(package('mysql-libs')).to_not be_installed
    end

    it 'has mysql55w-libs installed' do
      expect(package('mysql55w-libs')).to be_installed
    end
  end
end
