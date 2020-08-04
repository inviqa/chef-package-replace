# frozen_string_literal: true

source 'https://rubygems.org'

gem 'berkshelf', '~> 4.3'
gem 'chef', '~> 12.5'
gem 'rake', '>= 12.3.3'

group :integration do
  gem 'kitchen-vagrant', '~> 0.20'
  gem 'test-kitchen', '~> 1.7'
end

group :test do
  gem 'chefspec', '~> 4.6'
  gem 'foodcritic', '~> 6.2'
  gem 'rubocop', '>= 0.49.0'
end

group :deployment do
  gem 'stove', '~> 3.2.7'
end
