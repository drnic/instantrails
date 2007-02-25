Gem::Specification.new do |s|
  s.name = %q{cgi_multipart_eof_fix}
  s.version = "2.1"
  s.date = %q{2007-02-04}
  s.summary = %q{Fix an exploitable bug in CGI multipart parsing which affects Ruby <= 1.8.5 when multipart boundary attribute contains a non-halting regular expression string.}
  s.email = %q{evan at cloudbur dot st}
  s.homepage = %q{http://blog.evanweaver.com}
  s.rubyforge_project = %q{fauna}
  s.description = %q{Fix an exploitable bug in CGI multipart parsing which affects Ruby <= 1.8.5 when multipart boundary attribute contains a non-halting regular expression string.}
  s.has_rdoc = true
  s.authors = ["Evan Weaver"]
  s.files = ["README.txt", "LICENSE.txt", "Rakefile", "lib/cgi_multipart_eof_fix.rb", "cgi_multipart_eof_fix_test.rb"]
  s.test_files = ["cgi_multipart_eof_fix_test.rb"]
end
