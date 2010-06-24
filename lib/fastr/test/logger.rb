class Fastr::Log::Formatter
  def call(severity, time, progname, msg)
    #block all logging output during testing
  end
end