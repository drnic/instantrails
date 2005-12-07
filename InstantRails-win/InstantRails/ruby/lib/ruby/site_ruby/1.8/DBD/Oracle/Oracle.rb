#
# DBD::Oracle
#
# Copyright (c) 2001, 2002, 2003, 2004 Michael Neumann <mneumann@ntecs.de>
# 
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions 
# are met:
# 1. Redistributions of source code must retain the above copyright 
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright 
#    notice, this list of conditions and the following disclaimer in the 
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
# THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# $Id: Oracle.rb,v 1.7 2004/05/13 14:24:31 mneumann Exp $
#


#
# copied some code from lib/oracle.rb of Oracle 7 Module
# 

require "oracle"    # only depends on the oracle.so 
class OCIError
  def to_i
    if self.to_s =~ /^ORA-(\d+):/
      return $1.to_i
    end
    0
  end
end

module DBI
module DBD
module Oracle

  VARCHAR2 = 1
  NUMBER = 2
  INTEGER = 3 ## external
  FLOAT = 4   ## external
  LONG = 8
  ROWID = 11
  DATE = 12
  RAW = 23
  LONG_RAW = 24
  UNSIGNED_INT = 68 ## external
  CHAR = 96
  MLSLABEL = 105


  VERSION          = "0.2"
  USED_DBD_VERSION = "0.2"

class Driver < DBI::BaseDriver

  def initialize
    super(USED_DBD_VERSION)
  end

  def default_user
    ['scott', 'tiger']
  end

  def data_sources
    # read from $ORACLE_HOME/network/admin/tnsnames.ora
    []
  end

  def connect(dbname, user, auth, attr)
    # connect to database
    handle = ::ORAconn.logon(user, auth, dbname)
    return Database.new(handle, attr)
  rescue OCIError => err
    raise DBI::DatabaseError.new(err.message, err.to_i)
  end

end # class Driver


class Database < DBI::BaseDatabase
 
  def disconnect
    @handle.rollback
    @handle.logoff 
  rescue OCIError => err
    raise DBI::DatabaseError.new(err.message, err.to_i)
  end

  def ping
    begin
      stmt = execute("SELECT SYSDATE FROM DUAL /* ping */")
      stmt.fetch
      stmt.finish
      return true
    rescue OCIError
      return false
    end
  end

  def tables
    stmt = execute("SELECT object_name FROM user_objects " +
                   "WHERE object_type IN ('TABLE', 'VIEW')")  
    rows = stmt.fetch_all || []
    stmt.finish
    rows.collect {|row| row[0]} 
  end

  def prepare(statement)
    Statement.new(@handle, statement)
  end

  def []=(attr, value)
    case attr
    when 'AutoCommit'
      if value
        @handle.commiton
      else
        @handle.commitoff
      end
    else
      raise NotSupportedError
    end
    @attr[attr] = value

  rescue OCIError => err
    raise DBI::DatabaseError.new(err.message, err.to_i)
  end

  def commit
    @handle.commit
  rescue OCIError => err
    raise DBI::DatabaseError.new(err.message, err.to_i)
  end

  def rollback
    @handle.rollback
  rescue OCIError => err
    raise DBI::DatabaseError.new(err.message, err.to_i)
  end


    # from Jim Menard <jimm@io.com>
    ORACLE_TO_SQL = {
	'BLOB' => SQL_BLOB,
	'CHAR' => SQL_CHAR,
	'CLOB' => SQL_CLOB,
	'DATE' => SQL_DATE,
	'TIME' => SQL_TIME,
	'TIMESTAMP' => SQL_TIMESTAMP,
	'LONG' => SQL_LONGVARCHAR,
	'LONG RAW' => SQL_LONGVARBINARY,
	'RAW' => SQL_VARBINARY,
	'NUMBER' => SQL_NUMERIC,
	'FLOAT' => SQL_FLOAT,
	'ROWID' => SQL_DECIMAL, # That's a guess. Anyone?
	'VARCHAR' => SQL_VARCHAR,
	'VARCHAR2' => SQL_VARCHAR
    }
    IndexInfo = Struct.new('IndexInfo', :col_name, :index_name,
			   :is_unique, :is_primary)

    def columns(table)
	dbh = DBI::DatabaseHandle.new(self)

	# Find indexed columns and determine uniqueness. Keys of
	# "indexed" hash are index names (not column names) of index
	# columns. Values of "indexed" hash are IndexInfo structs.
	indexed = Hash.new{}
	sql = 'select a.column_name, a.index_name, b.uniqueness' +
	    ' from user_ind_columns a, user_indexes b' +
	    ' where a.index_name = b.index_name' +
	    ' and a.table_name = b.table_name' +
	    ' and a.table_name = upper(:1)'
	stmt = dbh.prepare(sql)
	stmt.execute(table)
	rows = stmt.fetch_all
	if rows
	    rows.each { | row |
		info = IndexInfo.new(row[0], row[1], row[2] == 'UNIQUE')
		indexed[row[1]] = info
	    }
	end

	# Find primary keys.
	sql = 'select constraint_name from user_constraints' +
	    ' where constraint_type = \'P\' and table_name = upper(:1)'
	stmt = dbh.prepare(sql)
	stmt.execute(table)
	rows = stmt.fetch_all
	if rows
	    rows.each { | row |
		# Oddly enough, some "primary key" constraints are not
		# table columns.
		indexed[row[0]].is_primary = true if indexed[row[0]]
	    }
	end

	# Find column type and size info.
	sql = 'select column_name, data_type, data_length, data_precision,' +
	    ' nullable, data_default' +
	    ' from user_tab_columns where table_name = upper(:1)'
	stmt = dbh.prepare(sql)
	stmt.execute(table)

	ret = stmt.fetch_all.collect { | row |
	    name, oracle_type, size, precision, nullable, default = row

	    # Find indexed info for this column, if it exists.
	    info = nil
	    if indexed
		indexed.each { | key, val |
		    info = val if val.col_name == name
		}
	    end

	    col = {}
	    col['name'] = name.dup
	    col['sql_type'] = ORACLE_TO_SQL[oracle_type] || SQL_OTHER
	    col['type_name'] = oracle_type.dup
	    col['nullable'] = nullable == 'Y'
	    col['indexed'] = !info.nil?
	    col['primary'] = info ? info.is_primary : false
	    col['unique'] = info ? info.is_unique : false
	    col['precision'] = size     # Number of bytes or digits
	    col['scale'] = precision    # number of digits to right
	    col['default'] = default ? default.dup : nil
	    col
	}
	return ret
    end

end # class Database


class Statement < DBI::BaseStatement

  def initialize(handle, statement)
    parse(handle, statement)
    @arr = Array.new(@ncols)
  end

  def bind_param(param, value, attribs)

    # TODO: check attribs
    ##
    # which SQL type?
    #
    #if value.kind_of? Integer
    #  vtype = INTEGER
    #elsif value.is_a? Float
    #  vtype = FLOAT

    if value.is_a? DBI::Binary
      vtype = LONG_RAW
    else
      vtype = VARCHAR2
    end

    param = ":#{param}" if param.is_a? Fixnum
    @handle.bindrv(param, value.to_s, vtype)
   
  rescue OCIError => err
    raise DBI::DatabaseError.new(err.message, err.to_i)
  end

  def cancel
    @handle.cancel
  rescue OCIError => err
    raise DBI::DatabaseError.new(err.message, err.to_i)
  end

  def execute
    @rows = @handle.exec
  rescue OCIError => err
    raise DBI::DatabaseError.new(err.message, err.to_i)
  end

  def finish
    @handle.close
  rescue OCIError => err
    raise DBI::DatabaseError.new(err.message, err.to_i)
  end

  def fetch
    rpc = @handle.fetch
    return nil if rpc.nil?

    (1..@ncols).each do |colnr|
      @arr[colnr-1] = @handle.getCol(colnr)[0]
    end 

    @arr
  rescue OCIError => err
    raise DBI::DatabaseError.new(err.message, err.to_i)
  end

  def column_info
    @colinfo
  end

  def rows
    @rows
  end

  private # ---------------------------------------------------
  
  class DummyQuoter
    # dummy to substitute ?-style parameter markers by :1 :2 etc.
    def quote(str)
      str
    end
  end

  def parse(handle, statement)
    @handle = handle.open

    # convert ?-style parameters to :1, :2 etc.
    prep_statement = DBI::SQL::PreparedStatement.new(DummyQuoter.new, statement)
    if prep_statement.unbound.size > 0
      arr = (1..(prep_statement.unbound.size)).collect{|i| ":#{i}"}
      statement = prep_statement.bind( arr ) 
    end

    begin
      @handle.parse(statement)
    rescue OCIError => err
      retry if err.to_i == 3123  ## block
    end   

    colnr = 1
    @colinfo = []
    loop {
      colinfo = @handle.describe(colnr)
      break if colinfo.nil?

      @colinfo << {'name' => colinfo[2]}

      collength, coltype = colinfo[3], colinfo[1]

      collength, coltype = case coltype
##      when NUMBER
##        [0, FLOAT]
      when NUMBER
        [40, VARCHAR2]
      when VARCHAR2, CHAR
        [(collength*1.5).ceil, VARCHAR2]
      when LONG
        [65535, LONG]
      when LONG_RAW
        [65535, LONG_RAW]
      else
        [collength, VARCHAR2]
      end
 

      #coltype = case coltype
      #  when ::Oracle::NUMBER then ::Oracle::FLOAT
      #  when ::Oracle::DATE   then ::Oracle::VARCHAR2
      #  else coltype
      #end

      @handle.define(colnr, collength, coltype)

      colnr += 1
    }
    @ncols = colnr - 1

  rescue OCIError => err
    raise DBI::DatabaseError.new(err.message, err.to_i)
  end

end


end # module Oracle
end # module DBD
end # module DBI

