Gem::Specification.new do |s|
  s.name = %q{builder}
  s.version = "2.0.0"
  s.date = %q{2006-02-04}
  s.summary = %q{Builders for MarkUp.}
  s.email = %q{jim@weirichhouse.org}
  s.homepage = %q{http://onestepback.org}
  s.description = %q{Builder provides a number of builder objects that make creating structured data simple to do.  Currently the following builder objects are supported:  * XML Markup * XML Events}
  s.autorequire = %q{builder}
  s.has_rdoc = true
  s.authors = ["Jim Weirich"]
  s.files = ["lib/builder.rb", "lib/builder/xmlmarkup.rb", "lib/builder/xmlbase.rb", "lib/builder/blankslate.rb", "lib/builder/xmlevents.rb", "lib/builder/xchar.rb", "test/testmarkupbuilder.rb", "test/testblankslate.rb", "test/preload.rb", "test/test_xchar.rb", "test/testeventbuilder.rb", "test/performance.rb", "scripts/publish.rb", "README", "Rakefile", "CHANGES", "doc/releases/builder-1.2.4.rdoc", "doc/releases/builder-2.0.0.rdoc"]
  s.test_files = ["test/testmarkupbuilder.rb", "test/testblankslate.rb", "test/test_xchar.rb", "test/testeventbuilder.rb"]
  s.rdoc_options = ["--title", "Builder -- Easy XML Building", "--main", "README", "--line-numbers"]
  s.extra_rdoc_files = ["README", "Rakefile", "CHANGES", "doc/releases/builder-1.2.4.rdoc", "doc/releases/builder-2.0.0.rdoc"]
end
