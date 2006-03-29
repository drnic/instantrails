Gem::Specification.new do |s|
  s.name = %q{win32-service}
  s.version = "0.5.0"
  s.date = %q{2006-02-21}
  s.summary = %q{win32-service for doing services in Ruby}
  s.has_rdoc = true
  s.required_ruby_version = Gem::Version::Requirement.new(">= 1.8.3")
  s.platform = %q{mswin32}
  s.authors = ["0.5.0"]
  s.files = ["ext/service/MANIFEST", "README", "Rakefile", "test/tc_daemon.rb", "test/tc_service.rb", "lib/win32", "lib/win32/service.so", "ext/service/service.h", "ext/service/win32-service-0.5.0/lib/win32/service.h", "ext/service/service.c", "ext/service/win32-service-0.5.0/lib/win32/service.c", "ext/service/extconf.rb", "ext/service/win32-service-0.5.0/extconf.rb", "ext/service/win32-service-0.5.0/examples/daemon_test.rb", "ext/service/win32-service-0.5.0/examples/services_test.rb", "ext/service/win32-service-0.5.0/test/tc_daemon.rb", "ext/service/win32-service-0.5.0/test/tc_service.rb", "examples/daemon_test.rb", "examples/services_test.rb", "tools/rakehelp.rb"]
  s.test_files = ["test/tc_service.rb"]
  s.extra_rdoc_files = ["README"]
end
