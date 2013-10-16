require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "fastr"
    gem.summary = %Q{Another rack web framework for Ruby.}
    gem.description = %Q{A fast, micro-framework for Ruby that should be run under EventMachine servers (thin)}
    gem.email = "chris@tech9computers.com"
    gem.homepage = "http://github.com/chrismoos/fastr"
    gem.authors = ["Chris Moos"]
    gem.files = ["lib/**/*.rb", "lib/**/*.rake"]
    gem.add_dependency "mime-types", "~> 1.16"
    gem.add_dependency "eventmachine"
    gem.add_dependency "json"
    gem.add_dependency "haml"
    gem.add_development_dependency "shoulda", ">= 0"
    gem.add_development_dependency "mocha"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "fastr #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
