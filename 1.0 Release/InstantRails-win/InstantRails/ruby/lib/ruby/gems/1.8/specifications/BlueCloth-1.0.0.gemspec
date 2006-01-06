Gem::Specification.new do |s|
  s.name = %q{BlueCloth}
  s.version = "1.0.0"
  s.date = %q{2004-08-31}
  s.summary = %q{BlueCloth is a Ruby implementation of Markdown, a text-to-HTML conversion tool for web writers. Markdown allows you to write using an easy-to-read, easy-to-write plain text format, then convert it to structurally valid XHTML (or HTML).}
  s.email = %q{ged@FaerieMUD.org}
  s.homepage = %q{http://bluecloth.rubyforge.org/}
  s.rubyforge_project = %q{bluecloth}
  s.autorequire = %q{bluecloth}
  s.bindir = nil
  s.has_rdoc = nil
  s.required_ruby_version = nil
  s.platform = nil
  s.files = ["./utils.rb", "./tests/bctestcase.rb", "./tests/00_Class.tests.rb", "./tests/05_Markdown.tests.rb", "./tests/10_Bug.tests.rb", "./tests/15_Contrib.tests.rb", "./tests/data/antsugar.txt", "./tests/data/ml-announce.txt", "./tests/data/re-overflow.txt", "./tests/data/re-overflow2.txt", "./test.rb", "./README", "./CHANGES", "./LICENSE", "./lib/bluecloth.rb", "./install.rb", "bin/bluecloth"]
  s.requirements = ["strscan", "logger"]
end
