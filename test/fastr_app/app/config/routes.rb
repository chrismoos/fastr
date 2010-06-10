router.draw do |route|
  route.for '/:controller/:action'
  route.for '/home/:action', :action => '[A-Za-z]+'
  route.for '/test', :to => 'home#index'
end