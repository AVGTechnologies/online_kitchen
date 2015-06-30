$: << 'lib'

require 'bundler/setup'
require File.expand_path('../app', __FILE__)

OnlineKitchen::App.run
