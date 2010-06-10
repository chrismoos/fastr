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
      
      context "when parsing mapping" do
        context "for standard controller" do
          setup { parse_route('/:controller/:action') }
        
          should "build proper regex" do
            assert_equal "^/(\\w+)/(\\w+)$",@route_map[:regex]
          end
        
          should "have no extra arguments" do
            assert_nil @route_map[:args]
          end
        
          should "have var for controller and action" do
            assert_equal [:controller,:action],@route_map[:vars]
          end
        
          should "have an empty hash" do
            assert @route_map[:hash].empty?
          end
        end
        
        context "with a regex match" do
          setup { parse_route("/home/:action",:action => '[A-Za-z]+') }
          
          should "build proper regex" do
            assert_equal "^/home/([A-Za-z]+)$",@route_map[:regex]
          end
        
          should "have one argument for the action regex" do
            assert_equal({:action=>"[A-Za-z]+"},@route_map[:args])
          end
        
          should "have var for the action matcher" do
            assert_equal [:action],@route_map[:vars]
          end
        
          should "have an empty hash" do
            assert @route_map[:hash].empty?
          end
        end
        
        context "with an exact match" do
          setup { parse_route("'/home/:action'",:to => 'home#index') }
        end
      end
    end 
  end
  
  def parse_route(route,*args)
    @router.for(route,*args)
    @route_map = @router.routes.first
  end 
end