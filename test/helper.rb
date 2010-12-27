require 'rubygems'
require 'eventmachine'
require 'test/unit'
require 'shoulda'
require 'mocha'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

APP_PATH = "#{File.expand_path(File.dirname(__FILE__))}/fastr_app"

require 'fastr'
EM.kqueue = true

class NueteredBootingApplication < Fastr::Application
  attr_reader :booted
  def boot
    @booted = true
  end
end

class ManualBootingApplication < Fastr::Application
  include Fastr::Log

  def initialize(path)
    self.app_path = path
    self.plugins = []
    @booting = true
  end
end

class Test::Unit::TestCase
  def em_setup(timeout = 0)
    EM.run do
      EM.add_timer(timeout) { EM.stop }
      yield
      EM.stop if timeout == 0
    end
  end
end

class Fastr::Log::Formatter
  def call(severity, time, progname, msg)
    #block all logging output during testing
    #puts "[#{severity}] [#{self.progname}]: #{msg}"
  end
end
