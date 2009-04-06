ENV['RDOCOPT'] = "-S -f html -T hanna"

require "rubygems"
require "hoe"
require File.dirname(__FILE__) << "/lib/resourcelogic/version"

Hoe.new("Resourcelogic", Resourcelogic::Version::STRING) do |p|
  p.name = "resourcelogic"
  p.author = "Ben Johnson of Binary Logic"
  p.email  = "bjohnson@binarylogic.com"
  p.summary = "Removes the need to namespace controllers, by adding context, among other things."
  p.description = "Removes the need to namespace controllers, by adding context, among other things."
  p.url = "http://github.com/binarylogic/resourcelogic"
  p.history_file = "CHANGELOG.rdoc"
  p.readme_file = "README.rdoc"
  p.extra_rdoc_files = ["CHANGELOG.rdoc", "README.rdoc"]
  p.remote_rdoc_dir = ""
  p.test_globs = ["test/*/test_*.rb", "test/*_test.rb", "test/*/*_test.rb"]
  p.extra_deps = %w(activesupport)
end