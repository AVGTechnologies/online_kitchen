source 'https://rubygems.org'

gem 'activerecord', '~>4.2.11.1'

gem 'annotate', '~> 2.6.6'

gem 'rails', '~>4.2.11.1', require: nil

gem 'redis', '4.1.2'
gem 'redis-namespace', '1.6.0'

gem 'sqlite3'

gem 'pg', '~>0.21'

gem 'sidekiq', '5.2.7'

gem 'metriks'

gem 'nokogiri', '~> 1.11.4'
gem 'savon', '~> 2.11'
gem 'sentry-raven' # ,    github: 'getsentry/raven-ruby'

gem 'strip_attributes', '~> 1.7.0'

gem 'rack', '~>1.6.2'
gem 'rack-contrib'
gem 'sinatra', '~> 1.4.6', require: 'sinatra/base' # see https://github.com/resque/resque/issues/934
gem 'sinatra-contrib', '~> 1.4.4'

gem 'activesupport'

gem 'settingslogic', '~> 2.0.9'

if RUBY_PLATFORM =~ /win32|mingw32/
  gem 'thin'
else
  gem 'puma'
end

group :test, :development do
  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'rspec'
  gem 'rubocop', '~> 0.74.0'
end
