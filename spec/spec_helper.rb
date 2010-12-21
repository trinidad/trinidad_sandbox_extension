begin
  require 'rspec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'rspec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'java'
require 'trinidad_sandbox_extension'
require 'mocha'

RSpec.configure do |config|
  config.mock_with :mocha
end
