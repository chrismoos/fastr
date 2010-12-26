require 'helper'

class TestDeferrableResponse < Test::Unit::TestCase

  context "DeferrableResponse" do
    setup do
      Fastr::Deferrable
      @response = Fastr::DeferrableResponse.new
    end

    should "hold onto callback to push data through to" do
      @response.each {|data| assert_equal "Some Data",data }
      @response.send_data("Some Data")
    end

    should "execute deferred tasks" do
      Object.expects(:touch!).times(2)
      em_setup do
        task = proc { Object.touch! }
        callback = proc { Object.touch! }
        @response.task(task,callback)
      end
    end

    should "call success callback when told to finish" do
      callback_path = nil
      em_setup do
        @response.callback { callback_path = "success" }
        @response.errback { callback_path = "failure" }
        @response.finish
      end
      assert_equal "success",callback_path
    end
  end
end
