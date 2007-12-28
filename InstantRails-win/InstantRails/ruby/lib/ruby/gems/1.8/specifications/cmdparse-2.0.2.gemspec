Gem::Specification.new do |s|
  s.name = %q{cmdparse}
  s.version = "2.0.2"

  s.specification_version = 1 if s.respond_to? :specification_version=

  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.authors = ["Thomas Leitner"]
  s.autorequire = %q{cmdparse}
  s.cert_chain = nil
  s.date = %q{2006-06-16}
  s.description = %q{cmdparse provides classes for parsing commands on the command line; command line options are parsed using optparse or any other option parser implementation. Programs that use such command line interfaces are, for example, subversion's 'svn' or Rubygem's 'gem' program.}
  s.email = %q{t_leitner@gmx.at}
  s.files = ["setup.rb", "TODO", "COPYING", "README", "Rakefile", "ChangeLog", "net.rb", "VERSION", "lib/cmdparse.rb", "lib/cmdparse/wrappers/optparse.rb", "doc/src", "doc/config.yaml", "doc/plugin", "doc/src/default.css", "doc/src/features.page", "doc/src/index.page", "doc/src/about.page", "doc/src/download.page", "doc/src/default.template", "doc/src/tutorial.page", "doc/src/meta.info", "doc/src/logo.png", "doc/plugin/extract.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://cmdparse.rubyforge.org}
  s.rdoc_options = ["--line-numbers", "-m", "CmdParse::CommandParser"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new("> 0.0.0")
  s.rubyforge_project = %q{cmdparse}
  s.rubygems_version = %q{1.0.1}
  s.summary = %q{Advanced command line parser supporting commands}
end
