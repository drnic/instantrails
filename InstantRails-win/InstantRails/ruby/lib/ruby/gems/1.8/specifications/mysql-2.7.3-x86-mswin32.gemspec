Gem::Specification.new do |s|
  s.name = %q{mysql}
  s.version = "2.7.3"
  s.platform = %q{mswin32}

  s.specification_version = 1 if s.respond_to? :specification_version=

  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.authors = ["Kevin Williams"]
  s.autorequire = %q{mysql}
  s.cert_chain = nil
  s.date = %q{2006-12-28}
  s.description = %q{A win32-native build of the MySQL API module for Ruby.}
  s.email = %q{kevin@bantamtech.com}
  s.extra_rdoc_files = ["README", "docs/README.html"]
  s.files = ["docs", "ext/mysql.so", "ext/extconf.rb", "ext/mysql.c.in", "ext/mysql.c.in.patch", "ext/test.rb", "README", "Rakefile", "docs/README.html"]
  s.has_rdoc = true
  s.homepage = %q{http://mysql-win.rubyforge.org}
  s.rdoc_options = ["--exclude", "ext", "--main", "README"]
  s.require_paths = ["ext"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.2")
  s.rubyforge_project = %q{mysql}
  s.rubygems_version = %q{1.0.1}
  s.summary = %q{A win32-native build of the MySQL API module for Ruby.}
end
