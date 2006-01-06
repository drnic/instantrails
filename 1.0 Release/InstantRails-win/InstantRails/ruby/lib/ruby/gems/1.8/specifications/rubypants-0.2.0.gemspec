Gem::Specification.new do |s|
  s.name = %q{rubypants}
  s.version = "0.2.0"
  s.date = %q{2004-11-15}
  s.summary = %q{RubyPants is a Ruby port of the smart-quotes library SmartyPants.}
  s.require_paths = ["."]
  s.email = %q{chneukirchen@gmail.com}
  s.homepage = %q{http://www.kronavita.de/chris/blog/projects/rubypants.html}
  s.description = %q{RubyPants is a Ruby port of the smart-quotes library SmartyPants.  The original "SmartyPants" is a free web publishing plug-in for Movable Type, Blosxom, and BBEdit that easily translates plain ASCII punctuation characters into "smart" typographic punctuation HTML entities.}
  s.files = ["install.rb", "rubypants.rb", "test_rubypants.rb", "README", "Rakefile"]
  s.test_files = ["test_rubypants.rb"]
  s.rdoc_options = ["--main", "README", "--line-numbers", "--inline-source", "--all", "--exclude", "test_rubypants.rb"]
  s.extra_rdoc_files = ["README"]
end
