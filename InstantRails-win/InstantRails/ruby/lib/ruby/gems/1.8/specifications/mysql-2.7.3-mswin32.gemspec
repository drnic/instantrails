Gem::Specification.new do |s|
  s.name = %q{mysql}
  s.version = "2.7.3"
  s.date = %q{2006-12-28}
  s.summary = %q{A win32-native build of the MySQL API module for Ruby.}
  s.require_paths = ["ext"]
  s.email = %q{kevin@bantamtech.com}
  s.homepage = %q{http://mysql-win.rubyforge.org}
  s.rubyforge_project = %q{mysql}
  s.description = %q{A win32-native build of the MySQL API module for Ruby.}
  s.autorequire = %q{mysql}
  s.has_rdoc = true
  s.required_ruby_version = Gem::Version::Requirement.new(">= 1.8.2")
  s.platform = %q{mswin32}
  s.authors = ["Kevin Williams"]
  s.files = ["docs", "ext/mysql.so", "ext/extconf.rb", "ext/mysql.c.in", "ext/mysql.c.in.patch", "ext/test.rb", "README", "Rakefile", "docs/README.html"]
  s.rdoc_options = ["--exclude", "ext", "--main", "README"]
  s.extra_rdoc_files = ["README", "docs/README.html"]
end
