Gem::Specification.new do |s|
  s.name = %q{mongrel_status}
  s.version = "0.2.2"
  s.date = %q{2006-03-14}
  s.summary = %q{A sample plugin that reports the status of mongrel.}
  s.description = %q{A sample plugin that reports the status of mongrel.}
  s.has_rdoc = true
  s.authors = ["Zed A. Shaw"]
  s.files = ["COPYING", "LICENSE", "README", "Rakefile", "test/test_empty.rb", "lib/mongrel_status", "lib/mongrel_status/init.rb", "tools/rakehelp.rb"]
  s.test_files = ["test/test_empty.rb"]
  s.extra_rdoc_files = ["README"]
  s.add_dependency(%q<mongrel>, [">= 0.3.11"])
  s.add_dependency(%q<gem_plugin>, [">= 0.2.1"])
end
