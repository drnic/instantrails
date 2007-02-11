=begin
= Ruby/DBI - a database independent interface for accessing databases - similar to Perl's DBI
$Id: index.rd,v 1.34 2004/04/22 19:59:46 mneumann Exp $

== License

Copyright (c) 2001, 2002, 2003, 2004 Michael Neumann <mneumann@ntecs.de> and others (see the beginning
of each file for copyright holder information). 

All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions 
are met:
(1) Redistributions of source code must retain the above copyright 
    notice, this list of conditions and the following disclaimer.
(2) Redistributions in binary form must reproduce the above copyright 
    notice, this list of conditions and the following disclaimer in the 
    documentation and/or other materials provided with the distribution.
(3) The name of the author may not be used to endorse or promote products
    derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

This is the BSD license which is less restrictive than GNU's GPL (General Public
License).

== Contributors

: Michael Neumann
  Author of Ruby/DBI; wrote the DBI and most of the DBDs (except DBD::Pg).
: Rainer Perl 
  Author of Ruby/DBI 0.0.4 from which many good ideas were taken into the new completely rewritten version 0.0.5. 
: Jim Weirich
  Author of the PostgreSQL driver (DBD::Pg).
  Wrote many additional code (e.g. sql.rb, testcases). 
  Gave many helpful hints and comments.
: Eli Green
  Implemented DatabaseHandle#columns for Mysql and Pg.
: Masatoshi SEKI
  For his version of module BasicQuote in sql.rb
: John Gorman 
  For his case insensitive load_driver patch and parameter parser.
: David Muse
  For testing the SQLRelay DBD and for his initial DBD. 
: Jim Menard
  Extending Oracle DBD for method columns.
: Joseph McDonald
  Fixed bug in DBD for PostgreSQL (default values in method columns).
: Norbert Gawor
  Fixed bug in DBD ODBC (method columns) and proxyserver.
: James F. Hranicky
  Patch for DBD Pg (cache PGResult#result in Tuples) which increases
  performance by a factor around 100
: Stephen Davies
  Added method Statement#fetch_scroll for PostgreSQL DBD.
: Dave Thomas
  Several enhancements.
: Daniel J. Berger
  contrib/dbrc
: Brad Hilton
  Column coercing patch for DBD Mysql.
: Sean Chittenden
  Submitted several patches and helped with lots of comments; Co-owner of the project.
: MoonWolf
  quote/escape_bytea patch for DBD Pg.
  DBD::SQLite patch and Database#columns implementation.
  Further patches.
: Paul DuBois
  Fixed typos and formatting. 
  Maintains DBD Mysql.
: Tim Bates
  Bug fixes for Mysql and DBI
: Brian Candler
  Zero-padding date/time/timestamps fix.
: Florian G. Pflug
  Discussion and helpful comments/benchmarks about DBD::Pg 
  async_exec vs. exec.
: Oliver M. Bolzer
  Patches to support Postgres arrays for DBD::Pg
: Stephen R. Veit
  ruby-db2 and DBD::DB2 enhancements.
: Dennis Vshivkov
  Postgres DBD patches
: Cail Borrell from frontbase.com
  For the Frontbase DBD and C interface.

== Database Drivers (DBDs)

* ADO (ActiveX Data Objects) ((*(dbd_ado)*))

  depend on WinOLE from RAA.

* DB2 ((*(dbd_db2)*))

  depend on Michael Neumann's Ruby/DB2 Module, available from RAA.

* Frontbase ((*(dbd_frontbase)*))

  depend on Cail Borrell's ruby-frontbase, available from RAA.

* InterBase ((*(dbd_interbase)*))

  depend on the InterBase module available from RAA.

* mSQL ((*(dbd_msql)*))

  depend on the "mSQL Library" by DATE Ken available from the RAA.

* MySQL ((*(dbd_mysql)*))

  depend on the "MySQL Ruby Module" by TOMITA Masahiro <tommy@tmtm.org> ((<URL:http://www.tmtm.org/mysql/>)) or
  available from the RAA.

* ODBC ((*(dbd_odbc)*))

  depend on the Ruby/ODBC (version >= 0.5) binding by Christian Werner <chw@ch-werner.de> 
  ((<URL:http://www.ch-werner.de/rubyodbc>)) or available from the RAA. 
  Works also together with unixODBC. To use the 'odbc_ignorecase' option you need Ruby/ODBC >= 0.9.3.

* Oracle ((*(dbd_oracle)*))

  depend on the "Oracle 7 Module for Ruby" version 0.2.11 by Yoshida Masato, available from RAA. Works fine with Oracle 8/8i.

* Oracle OCI8 ((*(dbd_oci8)*))

  ((<URL:http://www.jiubao.org/ruby-oci8/index.en.html>))

* PostgreSQL ((*(dbd_pg)*))

  depend on Noboru Saitou's Postgres Package:
  ((<URL:http://www.ruby-lang.org/en/raa-list.rhtml?name=postgres>))

* Proxy/Server ((*(dbd_proxy)*))

  depend on distributed Ruby (DRb) available from RAA.

* SQLite ((*(dbd_sqlite)*))

  depend only on the SQLite C-library from: ((<URL:http://www.hwaci.com/sw/sqlite/>)).

* SQLRelay ((*(dbd_sqlrelay)*))

  depend on the Ruby library of SQLRelay: ((<URL:http://www.firstworks.com/sqlrelay/>)).

* Sybase ((*(dbd_sybase)*))
  
  this DBD is currently outdated and will ((*not*)) work with DBI versions > 0.0.4 !!! 


== ChangeLog

See ((<URL:http://ruby-dbi.rubyforge.org/ChangeLog.html>)).

See ((<URL:http://ruby-dbi.rubyforge.org/ChangeLog>)) for the plain-text version.

== ToDo

See ((<URL:http://ruby-dbi.rubyforge.org/ToDo.html>)).


== Download

Ruby/DBI is available for from the ((<RubyForge project page|URL:http://rubyforge.org/frs/?group_id=234>)).

Older file releases can be downloaded for a limited time from ((<SourceForge project page|URL:http://sourceforge.net/project/showfiles.php?group_id=43737>)). But note that this will (hopefully) soon become obsolete.

If you're running FreeBSD or NetBSD, have a look at their package collections. FreeBSD has for DBI and each DBD an easy to
install package, NetBSD currently only for PostgreSQL but more is to come.

A NetBSD package for MySQL is available at ((<URL:http://www.fantasy-coders.de/ruby/ruby-mysql-2.4.tar.gz>)).

== Installation

All available DBDs come with this package, but you should only
install the DBDs you really need.

=== To install all:

   ruby setup.rb config
   ruby setup.rb setup
   ruby setup.rb install

=== To install dbi and some DBDs:

   ruby setup.rb config --with=dbi,dbd_pg....
   ruby setup.rb setup
   ruby setup.rb install

Choose the packages to install by specifing them after the option (({--with})).


== Mailing List
A mailinglist for DBI-specific discussions is available at the 
((<RubyForge project page|URL:http://rubyforge.org/projects/ruby-dbi>)).

Our former mailing-list was at ((<URL:http://groups.yahoo.com/group/ruby-dbi-talk>)); 
please, don't use it!

== Documentation

See the directories lib/*/doc or ext/*/doc for DBI and DBD specific informations.

The DBI specification is lib/dbi/doc/DBI_SPEC or lib/dbi/doc/html/DBI_SPEC.html or available
from WWW at ((<URL:http://ruby-dbi.rubyforge.org/DBI_SPEC.html>)).

The DBD specification (how to write a database driver) is lib/dbi/doc/DBD_SPEC or lib/dbi/doc/html/DBD_SPEC.html or available
from WWW at ((<URL:http://ruby-dbi.rubyforge.org/DBD_SPEC.html>)).

== Articles

* ((<Using the Ruby DBI Module|URL:http://www.kitebird.com/articles/ruby-dbi.html>)) by Paul DuBois.

== Applications

=== sqlsh.rb
The SQL command line interpreter sqlsh.rb is available in directory bin/commandline.
It gets installed by default.

== Examples

Examples can be found in the examples/ subdirectory.
In this directory there is the file proxyserver.rb which has to be run if you use the DBD::Proxy, 
to access databases remote over a TCP/IP network. 

=== A simple example
  require 'dbi'

  # connect to a datbase
  dbh = DBI.connect('DBI:Mysql:test', 'testuser', 'testpwd')

  puts "inserting..."
  1.upto(13) do |i|
     sql = "insert into simple01 (SongName, SongLength_s) VALUES (?, ?)"
     dbh.do(sql, "Song #{i}", "#{i*10}")
  end 

  puts "selecting..."
  sth=dbh.prepare('select * from simple01')
  sth.execute

  while row=sth.fetch do
   p row
  end

  puts "deleting..."
  dbh.do('delete from simple01 where internal_id > 10')

  dbh.disconnect

=== The same using Ruby's features

  require 'dbi'

  DBI.connect('DBI:Mysql:test', 'testuser', 'testpwd') do | dbh |

    puts "inserting..."
    sql = "insert into simple01 (SongName, SongLength_s) VALUES (?, ?)"
    dbh.prepare(sql) do | sth | 
      1.upto(13) { |i| sth.execute("Song #{i}", "#{i*10}") }
    end 

    puts "selecting..."
    dbh.select_all('select * from simple01') do | row |
      p row
    end

    puts "deleting..."
    dbh.do('delete from simple01 where internal_id > 10')

  end

=end 
