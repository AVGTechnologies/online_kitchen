source 'https://rubygems.org'

gem 'activerecord', '~>4.2.10'

gem 'annotate', '~> 2.6.6'

gem 'rails', '~>4.2.10', require: nil

gem 'redis-namespace', '1.5.2'

gem 'sqlite3'

gem 'pg', '~>0.15'

gem 'sidekiq', '4.1.4'

gem 'metriks'

gem 'nokogiri', '~> 1.8.2'
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
  gem 'rubocop', '~> 0.49.0'
end
