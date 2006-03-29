Gem::Specification.new do |s|
  s.name = %q{camping}
  s.version = "1.3"
  s.date = %q{2006-02-08}
  s.summary = %q{miniature rails for stay-at-home moms}
  s.email = %q{why@ruby-lang.org}
  s.homepage = %q{http://code.whytheluckystiff.net/camping/}
  s.rubyforge_project = %q{camping}
  s.default_executable = %q{camping}
  s.has_rdoc = true
  s.authors = ["why the lucky stiff"]
  s.files = ["README", "CHANGELOG", "examples/tepee", "examples/blog", "examples/charts", "examples/campsh", "examples/serve", "examples/tepee/tepee.rb", "examples/tepee/start", "examples/blog/blog.sqlite3", "examples/blog/blog.rb", "examples/blog/start", "examples/charts/charts", "examples/charts/pie.rb", "examples/charts/charts.rb", "examples/charts/start", "examples/campsh/campsh.rb", "lib/camping.rb", "lib/camping-unabridged.rb", "bin/camping", "extras/flipbook_rdoc.rb", "extras/Camping.gif"]
  s.rdoc_options = ["--quiet", "--title", "Camping, the Documentation", "--template", "extras/flipbook_rdoc.rb", "--opname", "index.html", "--line-numbers", "--main", "README", "--inline-source", "--exclude", "^(examples|extras)/", "--exclude", "lib/camping.rb"]
  s.extra_rdoc_files = ["README", "CHANGELOG"]
  s.executables = ["camping"]
  s.add_dependency(%q<activerecord>, [">= 1.13"])
  s.add_dependency(%q<markaby>, ["> 0.2"])
  s.add_dependency(%q<metaid>, ["> 0.0.0"])
end
