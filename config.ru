$: << 'lib'

require 'bundler/setup'
require File.expand_path('../app', __FILE__)


run OnlineKitchen::App

# following conde does not set bind properly:
# (see http://stackoverflow.com/a/27900704/1045752)
# run OnlineKitchen::App.new do |app|
#   app.settings.set :bind, '0.0.0.0'
# end
