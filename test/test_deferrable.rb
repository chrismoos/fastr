require 'helper'

class TestDeferrable < Test::Unit::TestCase
    
  context "Deferrable includer" do
    setup do
      @deferrable = DeferrableHost.new
      em_setup do
        @deferrable.defer_response(200, {"Content-Type" => "text/plain"}) do |response|
          response.send_data("hey\n")

          long_task = proc {
            response.send_data("processing...\n")
            return "finished"
          }

          callback = proc { |result|
            response.send_data("#{result}\n")
            response.succeed
          }

          response.task(long_task, callback)
        end
      end
    end
      
    should "pass sent data data through to server callback" do
      assert_not_nil @deferrable.callbacks.index("hey\n") 
    end
  
    should "run long task sent through response" do
      assert_not_nil @deferrable.callbacks.index("processing...\n")
    end
  end
end

class DeferrableHost
  include Fastr::Deferrable
  attr_accessor :callbacks
  
  def initialize
    @callbacks = []
  end
  
  def env
    {"async.callback"=>
      Proc.new{|array|
        response = array[2]
        response.each do |arg|
          @callbacks << arg
        end
      }
    }
  end
end