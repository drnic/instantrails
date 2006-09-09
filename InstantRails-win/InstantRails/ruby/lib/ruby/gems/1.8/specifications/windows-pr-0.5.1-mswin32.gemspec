Gem::Specification.new do |s|
  s.name = %q{windows-pr}
  s.version = "0.5.1"
  s.date = %q{2006-05-28}
  s.summary = %q{Windows functions and constants predefined via Win32API}
  s.email = %q{djberg96@gmail.com}
  s.homepage = %q{http://www.rubyforge.org/projects/win32utils}
  s.description = %q{Windows functions and constants predefined via Win32API}
  s.has_rdoc = true
  s.platform = %q{mswin32}
  s.authors = ["Daniel J. Berger"]
  s.files = ["doc/conversion_guide.txt", "lib/windows/clipboard.rb", "lib/windows/console.rb", "lib/windows/device_io.rb", "lib/windows/directory.rb", "lib/windows/error.rb", "lib/windows/eventlog.rb", "lib/windows/file.rb", "lib/windows/filesystem.rb", "lib/windows/handle.rb", "lib/windows/library.rb", "lib/windows/limits.rb", "lib/windows/memory.rb", "lib/windows/national.rb", "lib/windows/path.rb", "lib/windows/process.rb", "lib/windows/registry.rb", "lib/windows/security.rb", "lib/windows/shell.rb", "lib/windows/sound.rb", "lib/windows/synchronize.rb", "lib/windows/system_info.rb", "lib/windows/unicode.rb", "lib/windows/window.rb", "test/ts_all.rb", "lib/windows/msvcrt/buffer.rb", "lib/windows/msvcrt/file.rb", "test/tc_console.rb", "test/tc_error.rb", "test/tc_memory.rb", "test/tc_msvcrt_buffer.rb", "test/tc_path.rb", "test/tc_registry.rb", "test/tc_security.rb", "test/tc_synchronize.rb", "CHANGES", "MANIFEST", "README"]
  s.test_files = ["test/ts_all.rb"]
  s.extra_rdoc_files = ["README", "CHANGES"]
end
