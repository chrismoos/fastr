require 'helper'

class TestRouter < Test::Unit::TestCase
  context "" do
    setup { Fastr::Router.any_instance.stubs(:setup_watcher) }
    
    context "Newly Created Router" do
      setup do
        @router = Fastr::Router.new(NueteredBootingApplication.new(APP_PATH))
      end
    
      should "initialize an empty routes structure" do
        assert_equal [],@router.routes
      end
    
      should "infer directory of routes file" do
        assert_equal File.join(APP_PATH,"/app/config/routes.rb"),@router.route_file
      end
    end 
    
    # context "route parser" do
    #       setup do
    #         @router = Fastr::Router.new(NueteredBootingApplication.new(APP_PATH))
    #       end
    #     end
  end
 
end