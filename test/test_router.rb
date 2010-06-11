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
      
      context "when matching routes" do
        setup { @router.for('/:controller/:action') }
        
        should "map vars on valid route" do
          assert_equal({:ok => {:controller=>"test_controller",:action=>"test_action"}}, @router.match({'PATH_INFO' => "/test_controller/test_action"}))
        end
        
        should "return error map on invalid route" do
          assert_equal({:error => :not_found},@router.match({'PATH_INFO' => "/2o4598g7vher0023801293479/123twretbnsf g//sdfb s/test_action"}))
        end
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
          setup { parse_route("/test",:to => 'home#index') }
          
          should "build proper regex" do
            assert_equal "^/test$",@route_map[:regex]
          end
        
          should "have one argument for the direct route" do
            assert_equal({:to=>"home#index"},@route_map[:args])
          end
        
          should "have no vars" do
            assert @route_map[:vars].empty?
          end
        
          should "have a hash for the mapping" do
            assert_equal({:controller=>"home", :action=>"index"},@route_map[:hash])
          end
        end
      end
    end 
  end
  
  def parse_route(route,*args)
    @router.for(route,*args)
    @route_map = @router.routes.first
  end 
end