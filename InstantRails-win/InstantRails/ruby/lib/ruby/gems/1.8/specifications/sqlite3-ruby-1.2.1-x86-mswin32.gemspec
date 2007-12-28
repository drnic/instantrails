Gem::Specification.new do |s|
  s.name = %q{sqlite3-ruby}
  s.version = "1.2.1"
  s.platform = %q{mswin32}

  s.specification_version = 1 if s.respond_to? :specification_version=

  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.authors = ["Jamis Buck"]
  s.autorequire = %q{sqlite3}
  s.cert_chain = nil
  s.date = %q{2007-02-03}
  s.email = %q{jamis@37signals.com}
  s.extra_rdoc_files = ["README"]
  s.files = ["doc/faq", "doc/faq/faq.html", "doc/faq/faq.rb", "doc/faq/faq.yml", "ext/sqlite3_api", "ext/sqlite3_api/extconf.rb", "ext/sqlite3_api/Makefile", "ext/sqlite3_api/MANIFEST", "ext/sqlite3_api/sqlite3_api.i", "ext/sqlite3_api/sqlite3_api_wrap.c", "ext/sqlite3_api/win32", "ext/sqlite3_api/win32/build.bat", "lib/sqlite3", "lib/sqlite3.rb", "lib/sqlite3_api.so", "lib/sqlite3/constants.rb", "lib/sqlite3/database.rb", "lib/sqlite3/driver", "lib/sqlite3/errors.rb", "lib/sqlite3/pragmas.rb", "lib/sqlite3/resultset.rb", "lib/sqlite3/statement.rb", "lib/sqlite3/translator.rb", "lib/sqlite3/value.rb", "lib/sqlite3/version.rb", "lib/sqlite3/driver/dl", "lib/sqlite3/driver/native", "lib/sqlite3/driver/dl/api.rb", "lib/sqlite3/driver/dl/driver.rb", "lib/sqlite3/driver/native/driver.rb", "test/bm.rb", "test/driver", "test/mocks.rb", "test/native-vs-dl.rb", "test/tc_database.rb", "test/tc_errors.rb", "test/tc_integration.rb", "test/tests.rb", "test/driver/dl", "test/driver/dl/tc_driver.rb", "README"]
  s.has_rdoc = true
  s.homepage = %q{http://sqlite-ruby.rubyforge.org/sqlite3}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.0")
  s.rubygems_version = %q{1.0.1}
  s.summary = %q{SQLite3/Ruby is a module to allow Ruby scripts to interface with a SQLite database.}
  s.test_files = ["test/tests.rb"]
end
