Gem::Specification.new do |s|
  s.name = %q{gem_plugin}
  s.version = "0.2.1"
  s.date = %q{2006-03-14}
  s.summary = %q{A plugin system based only on rubygems that uses dependencies only}
  s.description = %q{A plugin system based only on rubygems that uses dependencies only}
  s.default_executable = %q{gpgen}
  s.has_rdoc = true
  s.authors = ["Zed A. Shaw"]
  s.files = ["COPYING", "LICENSE", "README", "Rakefile", "bin/gpgen", "doc/rdoc/classes", "doc/rdoc/created.rid", "doc/rdoc/files", "doc/rdoc/fr_class_index.html", "doc/rdoc/fr_file_index.html", "doc/rdoc/fr_method_index.html", "doc/rdoc/index.html", "doc/rdoc/rdoc-style.css", "doc/rdoc/classes/GemPlugin", "doc/rdoc/classes/GemPlugin.html", "doc/rdoc/classes/GemPlugin.src", "doc/rdoc/classes/GemPlugin/Base.html", "doc/rdoc/classes/GemPlugin/Base.src", "doc/rdoc/classes/GemPlugin/Manager.html", "doc/rdoc/classes/GemPlugin/Manager.src", "doc/rdoc/classes/GemPlugin/PluginNotLoaded.html", "doc/rdoc/classes/GemPlugin/Base.src/M000002.html", "doc/rdoc/classes/GemPlugin/Base.src/M000003.html", "doc/rdoc/classes/GemPlugin/Base.src/M000004.html", "doc/rdoc/classes/GemPlugin/Manager.src/M000005.html", "doc/rdoc/classes/GemPlugin/Manager.src/M000006.html", "doc/rdoc/classes/GemPlugin/Manager.src/M000007.html", "doc/rdoc/classes/GemPlugin/Manager.src/M000008.html", "doc/rdoc/classes/GemPlugin/Manager.src/M000009.html", "doc/rdoc/classes/GemPlugin/Manager.src/M000010.html", "doc/rdoc/classes/GemPlugin/Manager.src/M000011.html", "doc/rdoc/classes/GemPlugin.src/M000001.html", "doc/rdoc/files/COPYING.html", "doc/rdoc/files/lib", "doc/rdoc/files/LICENSE.html", "doc/rdoc/files/README.html", "doc/rdoc/files/lib/gem_plugin_rb.html", "test/test_plugins.rb", "lib/gem_plugin.rb", "tools/rakehelp.rb", "resources/COPYING", "resources/doc", "resources/lib", "resources/LICENSE", "resources/Rakefile", "resources/README", "resources/resources", "resources/test", "resources/tools", "resources/lib/project", "resources/lib/project/init.rb", "resources/resources/defaults.yaml", "resources/tools/rakehelp.rb"]
  s.test_files = ["test/test_plugins.rb"]
  s.extra_rdoc_files = ["README"]
  s.executables = ["gpgen"]
  s.add_dependency(%q<rake>, [">= 0.7"])
end
