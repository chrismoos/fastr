module Fastr
  # All controllers in a Fastr application should inherit from this class.
  #
  # == Sample Controller
  #
  #   class HomeController < Fastr::Controller
  #     def index
  #       [200, {"Content-Type" => "text/plain"}, ["Hello, World!"]]
  #     end
  #   end
  #
  # == Response headers
  # 
  # You can add response headers directly by accessing the instance attribute {#headers}.
  #
  #   self.headers['My-Header'] = 'value'
  #
  #
  # == Cookies
  #
  # You can access cookies in the request by accessing the instance attribute {#cookies}.
  #
  #   self.cookies['MYCOOKIE']
  #
  # == Params
  #
  # You can access the parameters in the request by accessing the instance attribute {#params}.
  #
  #   self.params['paramSentInRequest']
  #
  # @author Chris Moos
  class Controller
    # The current Rack environment for the request.
    #
    # @return [Hash]
    attr_accessor :env
    
    # The params for this request.
    #
    # @return [Hash]
    attr_accessor :params
    
    # The application for the controller's current request.
    #
    # @return [Fastr::Application]
    attr_accessor :app
    
    # Headers to send in the response.
    #
    # @return [Hash]
    attr_accessor :headers
    
    # Cookies sent in the request
    #
    # @return [Hash]
    attr_accessor :cookies
    
    include Fastr::Template
    include Fastr::Deferrable
    include Fastr::Cookie
    include Fastr::Filter
    
    def self.inherited(kls)
      kls.instance_eval('include Fastr::Log')
    end
    
  end
end