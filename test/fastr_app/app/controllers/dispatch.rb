class DispatchController < Fastr::Controller
  def simple
    [200, {"Content-Type" => "text/plain"}, ["success"]]
  end
  
  def simple_header
    self.headers['Test-Header'] = 'abc'
    [200, {}, ["success"]]
  end
  
  def test_get_params
    [200, {}, [get_params, params]]
  end
  
  def test_post_params
    [200, {}, [post_params, params]]
  end
  
  def test_controller_params
    [200, {}, [[params[:controller], params[:action]]]]
  end
  
  def test_cookies
    [200, {}, [cookies]]
  end
end