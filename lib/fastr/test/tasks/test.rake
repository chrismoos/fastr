require 'rake'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.libs << "lib"
  t.name = "fastr:test"
  t.test_files = FileList['test/**/test_*.rb']
  t.verbose = true
end