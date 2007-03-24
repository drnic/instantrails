
DESCRIPTION

Fix an exploitable bug in CGI multipart parsing which affects Ruby <= 1.8.5
when multipart boundary attribute contains a non-halting regular expression
string. The boundary searcher in the CGI module does not properly escape 
the user-supplied parameter and will execute arbitrary regular expressions. 
The fix adds escaping for the user data.

This is fix is cumulative with previous CGI multipart vulnerability fixes; see
version 1.0.0 of the gem by Zed Shaw.

SCOPE

Affected: standalone CGI, Mongrel, WEBrick
Unaffected: FastCGI
Unknown: mod_ruby

USAGE

Install the hotfix gem and  run the included test to verify the flaw is 
corrected. You must require the gem in every affected application, as follows:

  require 'rubygems' 
  require 'cgi_multipart_eof_fix'

If you only use mongrel_rails for application hosting, you may install mongrel 
like so:

  sudo gem install mongrel --source=http://mongrel.rubyforge.org/releases
  
Then mongrel will require the fix for you, provided you have installed version 2.0.0
of this gem. This is a hack, and mongrel may change in the future.

RESOURCES

http://www.ruby-lang.org/en/news/2006/12/04/another-dos-vulnerability-in-cgi-library/
http://blog.evanweaver.com/articles/2006/12/05/cgi-rb-vulnerability-hotfix
http://blog.evanweaver.com/articles/2006/12/05/new-cgi-rb-vulnerability
    
LICENSE

Copyright 2006, 2007 Cloudburst, LLC. Portions copyright 2006 Zed A. Shaw,
Yukihiro Matsumoto and used with permission. Licensed under the AFL 3.0. 
See the included LICENSE.txt file.