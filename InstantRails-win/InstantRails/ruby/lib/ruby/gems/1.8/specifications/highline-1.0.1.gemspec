Gem::Specification.new do |s|
  s.name = %q{highline}
  s.version = "1.0.1"
  s.date = %q{2005-07-07}
  s.summary = %q{HighLine is a high-level line oriented console interface.}
  s.email = %q{james@grayproductions.net}
  s.homepage = %q{http://highline.rubyforge.org}
  s.rubyforge_project = %q{highline}
  s.description = %q{A "high-level line oriented" input/output library that grew out of my solution to Ruby Quiz #29. This library attempts to make standard console input and output robust and painless.}
  s.autorequire = %q{highline}
  s.has_rdoc = true
  s.authors = ["James Edward Gray II"]
  s.files = ["examples/ansi_colors.rb", "examples/asking_for_arrays.rb", "examples/basic_usage.rb", "examples/menus.rb", "examples/page_and_wrap.rb", "examples/password.rb", "examples/using_readline.rb", "lib/highline.rb", "lib/highline/import.rb", "lib/highline/menu.rb", "lib/highline/question.rb", "test/tc_highline.rb", "test/tc_import.rb", "test/tc_menu.rb", "test/ts_all.rb", "Rakefile", "setup.rb", "README", "INSTALL", "TODO", "CHANGELOG", "LICENSE"]
  s.test_files = ["test/ts_all.rb"]
  s.rdoc_options = ["--title", "HighLine Documentation", "--main", "README"]
  s.extra_rdoc_files = ["README", "INSTALL", "TODO", "CHANGELOG", "LICENSE"]
end
