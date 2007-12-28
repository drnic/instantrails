Gem::Specification.new do |s|
  s.name = %q{net-sftp}
  s.version = "1.1.0"

  s.specification_version = 1 if s.respond_to? :specification_version=

  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.authors = ["Jamis Buck"]
  s.autorequire = %q{net/sftp}
  s.cert_chain = nil
  s.date = %q{2006-01-02}
  s.email = %q{jamis@jamisbuck.org}
  s.files = ["doc/faq", "doc/LICENSE-BSD", "doc/LICENSE-GPL", "doc/LICENSE-RUBY", "doc/faq/faq.html", "doc/faq/faq.rb", "doc/faq/faq.yml", "lib/net", "lib/uri", "lib/net/sftp", "lib/net/sftp.rb", "lib/net/sftp/errors.rb", "lib/net/sftp/operations", "lib/net/sftp/protocol", "lib/net/sftp/session.rb", "lib/net/sftp/version.rb", "lib/net/sftp/operations/abstract.rb", "lib/net/sftp/operations/close.rb", "lib/net/sftp/operations/errors.rb", "lib/net/sftp/operations/fsetstat.rb", "lib/net/sftp/operations/fstat.rb", "lib/net/sftp/operations/lstat.rb", "lib/net/sftp/operations/mkdir.rb", "lib/net/sftp/operations/open.rb", "lib/net/sftp/operations/opendir.rb", "lib/net/sftp/operations/read.rb", "lib/net/sftp/operations/readdir.rb", "lib/net/sftp/operations/realpath.rb", "lib/net/sftp/operations/remove.rb", "lib/net/sftp/operations/rename.rb", "lib/net/sftp/operations/rmdir.rb", "lib/net/sftp/operations/services.rb", "lib/net/sftp/operations/setstat.rb", "lib/net/sftp/operations/stat.rb", "lib/net/sftp/operations/write.rb", "lib/net/sftp/protocol/01", "lib/net/sftp/protocol/02", "lib/net/sftp/protocol/03", "lib/net/sftp/protocol/04", "lib/net/sftp/protocol/05", "lib/net/sftp/protocol/constants.rb", "lib/net/sftp/protocol/driver.rb", "lib/net/sftp/protocol/packet-assistant.rb", "lib/net/sftp/protocol/services.rb", "lib/net/sftp/protocol/01/attributes.rb", "lib/net/sftp/protocol/01/impl.rb", "lib/net/sftp/protocol/01/packet-assistant.rb", "lib/net/sftp/protocol/01/services.rb", "lib/net/sftp/protocol/02/impl.rb", "lib/net/sftp/protocol/02/packet-assistant.rb", "lib/net/sftp/protocol/02/services.rb", "lib/net/sftp/protocol/03/impl.rb", "lib/net/sftp/protocol/03/packet-assistant.rb", "lib/net/sftp/protocol/03/services.rb", "lib/net/sftp/protocol/04/attributes.rb", "lib/net/sftp/protocol/04/impl.rb", "lib/net/sftp/protocol/04/packet-assistant.rb", "lib/net/sftp/protocol/04/services.rb", "lib/net/sftp/protocol/05/impl.rb", "lib/net/sftp/protocol/05/packet-assistant.rb", "lib/net/sftp/protocol/05/services.rb", "lib/uri/open-sftp.rb", "lib/uri/sftp.rb", "examples/asynchronous.rb", "examples/get-put.rb", "examples/sftp-open-uri.rb", "examples/ssh-service.rb", "examples/synchronous.rb", "test/ALL-TESTS.rb", "test/operations", "test/protocol", "test/operations/tc_abstract.rb", "test/operations/tc_close.rb", "test/operations/tc_fsetstat.rb", "test/operations/tc_fstat.rb", "test/operations/tc_lstat.rb", "test/operations/tc_mkdir.rb", "test/operations/tc_open.rb", "test/operations/tc_opendir.rb", "test/operations/tc_read.rb", "test/operations/tc_readdir.rb", "test/operations/tc_realpath.rb", "test/operations/tc_remove.rb", "test/operations/tc_rmdir.rb", "test/operations/tc_setstat.rb", "test/operations/tc_stat.rb", "test/operations/tc_write.rb", "test/protocol/01", "test/protocol/02", "test/protocol/03", "test/protocol/04", "test/protocol/05", "test/protocol/tc_driver.rb", "test/protocol/01/tc_attributes.rb", "test/protocol/01/tc_impl.rb", "test/protocol/01/tc_packet_assistant.rb", "test/protocol/02/tc_impl.rb", "test/protocol/02/tc_packet_assistant.rb", "test/protocol/03/tc_impl.rb", "test/protocol/03/tc_packet_assistant.rb", "test/protocol/04/tc_attributes.rb", "test/protocol/04/tc_impl.rb", "test/protocol/04/tc_packet_assistant.rb", "test/protocol/05/tc_impl.rb", "test/protocol/05/tc_packet_assistant.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://net-ssh.rubyforge.org/sftp}
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new("> 0.0.0")
  s.rubygems_version = %q{1.0.1}
  s.summary = %q{Net::SFTP is a pure-Ruby implementation of the SFTP client protocol.}
  s.test_files = ["test/ALL-TESTS.rb"]

  s.add_dependency(%q<net-ssh>, [">= 1.0.0"])
end
