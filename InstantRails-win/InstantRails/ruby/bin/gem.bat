@echo off
if not "%~f0" == "~f0" goto WinNT
ruby -Sx "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofruby
:WinNT
"%~d0%~p0ruby" -x "%~f0" %*
goto endofruby
#!/bin/ruby

require 'rubygems'
Gem.manage_gems

required_version = Gem::Version::Requirement.new(">= 1.8.0")
unless  required_version.satisfied_by?(Gem::Version.new(RUBY_VERSION))
  puts "Expected Ruby Version #{required_version}, was #{RUBY_VERSION}"
  exit(1)
end

# We need to preserve the original ARGV to use for passing gem options
# to source gems.  If there is a -- in the line, strip all options after
# it...its for the source building process.
args = !ARGV.include?("--") ? ARGV.clone : ARGV[0...ARGV.index("--")]

Gem::GemRunner.new.run(args)

__END__
:endofruby
