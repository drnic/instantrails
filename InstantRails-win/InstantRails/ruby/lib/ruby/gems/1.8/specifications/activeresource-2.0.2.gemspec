Gem::Specification.new do |s|
  s.name = %q{activeresource}
  s.version = "2.0.2"

  s.specification_version = 2 if s.respond_to? :specification_version=

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Heinemeier Hansson"]
  s.autorequire = %q{active_resource}
  s.date = %q{2007-12-20}
  s.description = %q{Wraps web resources in model classes that can be manipulated through XML over REST.}
  s.email = %q{david@loudthinking.com}
  s.extra_rdoc_files = ["README"]
  s.files = ["Rakefile", "README", "CHANGELOG", "lib/active_resource", "lib/active_resource/base.rb", "lib/active_resource/connection.rb", "lib/active_resource/custom_methods.rb", "lib/active_resource/formats", "lib/active_resource/formats/json_format.rb", "lib/active_resource/formats/xml_format.rb", "lib/active_resource/formats.rb", "lib/active_resource/http_mock.rb", "lib/active_resource/validations.rb", "lib/active_resource/version.rb", "lib/active_resource.rb", "lib/activeresource.rb", "test/abstract_unit.rb", "test/authorization_test.rb", "test/base", "test/base/custom_methods_test.rb", "test/base/equality_test.rb", "test/base/load_test.rb", "test/base_errors_test.rb", "test/base_test.rb", "test/connection_test.rb", "test/fixtures", "test/fixtures/beast.rb", "test/fixtures/person.rb", "test/fixtures/street_address.rb", "test/format_test.rb", "test/setter_trap.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://www.rubyonrails.org}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{activeresource}
  s.rubygems_version = %q{1.0.1}
  s.summary = %q{Think Active Record for web resources.}

  s.add_dependency(%q<activesupport>, ["= 2.0.2"])
end
