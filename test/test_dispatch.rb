require 'helper'
require 'mocha'

class TestDispatch < Test::Unit::TestCase
  include Fastr::Dispatch
  include Fastr::Log

  attr_accessor :plugins, :app

  def method_missing(name, *args)
    self.app.send(name, *args)
  end

  context "dispatching a request" do
    setup do
      self.plugins = []
      em_setup do
        self.app = NueteredBootingApplication.new(APP_PATH)
        self.app.router = Fastr::Router.new(self.app)
      end
    end

    should "return server not ready if booting" do
      @booting = true

      code, headers, body = *dispatch({})
      assert_equal(500, code)
      assert_equal({'Content-Type' => 'text/plain'}, headers)
      assert_equal(["Server Not Ready"], body)
    end

    context "when doing dispatch" do
      should "return static file if it exists" do
        env = {"PATH_INFO" => "/static.txt"}
        code, headers, body = *do_dispatch(env)
        assert_equal(200, code)
        assert_equal('text/plain', headers['Content-Type'])
        assert_equal(['static'], body)
      end

      should "return 404 if no route exists" do
        env = {"PATH_INFO" => "/some/invalid/route"}
        code, headers, body = *do_dispatch(env)
        assert_equal(404, code)
        assert_equal('text/plain', headers['Content-Type'])
        assert_equal(['404 Not Found: /some/invalid/route'], body)
      end

      context "and routing to a controller" do
        should "return the response" do
          env = {"PATH_INFO" => "/"}
          self.app.router.for '/', :to => "dispatch#simple"
          response = do_dispatch(env)
          assert_equal([200, {"Content-Type" => "text/plain"}, ["success"]], response)
        end

        should "merge the controller's headers into the response" do
          env = {"PATH_INFO" => "/"}
          self.app.router.for '/', :to => "dispatch#simple_header"
          code, headers, body = *do_dispatch(env)
          assert_equal(200, code)
          assert_equal('abc', headers['Test-Header'])
          assert_equal(['success'], body)
        end

        should "set controller and action params" do
          env = {"PATH_INFO" => "/"}
          self.app.router.for '/', :to => "dispatch#test_controller_params"
          code, headers, body = *do_dispatch(env)
          assert_equal('dispatch', body[0][0])
          assert_equal('test_controller_params', body[0][1])
        end

        should "set get params for a get request" do
          env = {"PATH_INFO" => "/", "QUERY_STRING" => "a=b&c=d", "REQUEST_METHOD" => "GET"}
          params = {'a' => 'b', 'c' => 'd'}
          self.app.router.for '/', :to => "dispatch#test_get_params"
          code, headers, body = *do_dispatch(env)
          assert_equal(params, body[0])

          params.each do |k,v|
            assert(body[1].has_key? k)
            assert(v, body[1][k])
          end
        end

        should "set post params for a post request" do
          env = {"PATH_INFO" => "/", "rack.input" => StringIO.new("a=b&c=d"), "REQUEST_METHOD" => "POST"}
          params = {'a' => 'b', 'c' => 'd'}
          self.app.router.for '/', :to => "dispatch#test_post_params"
          code, headers, body = *do_dispatch(env)
          assert_equal(params, body[0])

          params.each do |k,v|
            assert(body[1].has_key? k)
            assert(v, body[1][k])
          end
        end

        should "set cookies" do
          env = {"PATH_INFO" => "/", "HTTP_COOKIE" => "a = b; c = d;", "REQUEST_METHOD" => "GET"}
          cookies = {'a' => 'b', 'c' => 'd'}
          self.app.router.for '/', :to => "dispatch#test_cookies"
          code, headers, body = *do_dispatch(env)

          cookies.each do |k,v|
            assert(body[0].has_key? k)
            assert(v, body[0][k])
          end
        end

        should "preserve headers if render is called" do
          env = {"PATH_INFO" => "/"}
          self.app.router.for '/', :to => "dispatch#render_header"
          code, headers, body = *do_dispatch(env)
          assert_equal(200, code)
          assert_equal('abc', headers['Test-Header'])
          assert_equal(['success'], body)
        end
      end
    end
  end


end
