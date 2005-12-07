##
## Oracle module for Ruby
## 1998-2000 by yoshidam
##

require 'oracle.so'

class Oracle
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

  def initialize(uid = nil, pswd = nil, conn = nil)
    @autocommit = false
    if uid.nil? && pswd.nil? && conn.nil?
      @conn = ORAconn.getConnection
    else
      @conn = ORAconn.logon(uid, pswd, conn)
    end
  end

  def logoff
    @conn.rollback
    @conn.logoff
  end

  def exec(sql, *bindvars)
    cursor = Oracle::Cursor.new(@conn, sql, *bindvars)
    if iterator?
      begin
        cursor.fetch { |row| yield(row) }   # for each row
      rescue OCIError
        raise
      ensure
        cursor.close # if cursor
      end
    else
      cursor
    end
  end

  def parse(sql)
    cursor = Oracle::Cursor.new(@conn)
    cursor.parse(sql)
    cursor
  end

  def commit
    @conn.commit
  end

  def rollback
    @conn.rollback
  end

  def autocommit
    @autocommit
  end

  def autocommit=(ac)
    if !@autocommit and ac
      @conn.commiton
    elsif @autocommit and !ac
      @conn.commitoff
    end
    @autocommit = ac
  end

  class RawData
    attr :value
    def initialize(str)
      @value = str
    end
  end

  def self::Binary(str)
    RawData.new(str)
  end

  class Cursor
    def initialize(conn, sql=nil, *bindvars)
      @cursor = conn.open
      if sql
        parse(sql)
        bind(*bindvars)
        @cursor.exec
      end
    end

    def parse(sql)
      begin
        @cursor.parse(sql)
      rescue OCIError
        retry if $!.to_i == 3123  ## block
        raise
      end

      i = 0
      @desc = []
      while desc = @cursor.describe(i + 1)
        @desc.push(desc)
        case desc[1]
##        when NUMBER
##          @cursor.define(i + 1, 0, FLOAT)
        when NUMBER
          @cursor.define(i + 1, 40, VARCHAR2)
        when VARCHAR2, CHAR
          @cursor.define(i + 1, (desc[3]*1.5).ceil, VARCHAR2)
        when LONG
          @cursor.define(i + 1, 65535, LONG)
        when LONG_RAW
          @cursor.define(i + 1, 65535, LONG_RAW)
        else
          @cursor.define(i + 1, desc[3], VARCHAR2)
        end
        i += 1
      end
      @cols = i
    end

    def bind(*bindvars)
      bindvars.each_with_index do |val, i|
        if val.is_a?(RawData)
          @cursor.bindrv(":#{i}", val.value, LONG_RAW)
        else
          @cursor.bindrv(":#{i}", val)
        end
      end
    end

    def exec(*bindvars)
      bind(*bindvars)
      @cursor.exec
    end

    def getColNames
      ret = []
      @desc.each do |d|
        ret.push(d[2])
      end
      ret
    end

    def getDWidth
      ret = []
      @desc.each do |d|
        ret.push(d[3])
      end
      ret
    end

    def getColumn(pos)
      val = @cursor.getCol(pos)
      if @desc[pos-1][1] == NUMBER && !val[0].nil?
        if @desc[pos-1][4] != 0 && @desc[pos-1][5] == 0
          val[0] = val[0].to_i
        else
          val[0] = val[0].to_f
        end
      end
      val
    end
    private :getColumn

    def fetch
      if iterator?
        while !@cursor.fetch.nil?
          ret = []
          (1..@cols).each do |i|
            val = getColumn(i)
            ret.push(val[0])
          end
          yield(ret)
        end
      else
        if @cursor.fetch.nil?
          return nil
        end
        ret = []
        (1..@cols).each do |i|
          val = getColumn(i)
          ret.push(val[0])
        end
        ret
      end
    end

    def close
      @cursor.close
    end
  end
end

class OCIError
  def to_i
    if self.to_s =~ /^ORA-(\d+):/
      return $1.to_i
    end
    0
  end
end
