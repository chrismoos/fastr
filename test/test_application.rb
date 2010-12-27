require 'helper'

class TestApplication < Test::Unit::TestCase

  context "New Application" do
    setup do
      em_setup{ @application = NueteredBootingApplication.new("/some/path") }
    end

    should "store startup path" do
      assert_equal "/some/path",@application.app_path
    end

    should "boot application" do
      assert @application.booted
    end
  end

  context "Application Boot" do
    setup do
      em_setup {
        @application = ManualBootingApplication.new(APP_PATH)
        @application.send(:boot).join
      }
    end

    should "load settings file" do
      assert($fastr_settings_loaded)
    end

    should "load app controllers" do
      assert defined?(FastrAppController)
    end

    should "create router" do
      assert_not_nil @application.router
    end

    should "setup routes from route file" do
      assert_equal 3,@application.router.routes.size
    end
  end
end
