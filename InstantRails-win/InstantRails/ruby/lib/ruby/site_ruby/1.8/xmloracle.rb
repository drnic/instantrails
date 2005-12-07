##
## Oracle-XML module
## 1999 by yoshidam
##

require 'oracle'

class Oracle
  def getXMLfromTable(table, cond = nil)
    ## get column names
    sql = "select * from " + table + " where rowid = ''"
    c = self.exec(sql)
    cols = c.getColNames
    cols.unshift("ROWID")
    c.close

    ## query
    sql = "select " + cols.join(",") + " from " + table
    sql << " " + cond if cond
    c = self.exec(sql)

    ## fetch and create XML
    ret = c.getXMLwithID(table)
    c.close
    ret
  end

  class Cursor
    ENCODING_MAP = {
      "US7ASCII", "US-ASCII",
      "WE8ISO8859P1", "ISO-8859-1",
      "EE8ISO8859P2", "ISO-8859-2",
      "SE8ISO8859P3", "ISO-8859-3",
      "NEE8ISO8859P4", "ISO-8859-4",
      "CL8ISO8859P5", "ISO-8859-5",
      "AR8ISO8859P6", "ISO-8859-6",
      "EL8ISO8859P7", "ISO-8859-7",
      "IW8ISO8859P8", "ISO-8859-8",
      "WE8ISO8859P9", "ISO-8859-9",
      "NE8ISO8859P10", "ISO-8859-10",
      "JA16EUC", "EUC-JP",
      "JA16SJIS", "Shift_JIS",
      "ZHS16GBK", "GB2312",
      "ZHT16BIG5", "Big5",
      "KO16KSC5601", "EUC-KR",
      "UTF8", "UTF-8"
    }
    ORACLE_TYPE = {
      1, "VARCHAR2",
      2, "NUMBER",
      8, "LONG",
      11, "ROWID",
      12, "DATE",
      23, "RAW",
      24, "LONG_RAW",
      96, "CHAR",
      105, "MLSLABEL"
    }
    NONNAMECHAR = Regexp.quote(" !\"#\$%&'()*+,./:;<=>?@[\\]^\`{|}~")

    def nameconv(str)
      str = str.gsub("[" + NONNAMECHAR + "]") {|c|
               format(".%02X.", c[0])
             }
    end

    def textconv(str)
      str = str.to_s.gsub('&', "&#38;")
      str = str.gsub('\'', "&#39;")
      str = str.gsub('\"', "&#34;")
      str = str.gsub('<', "&#60;")
      str.gsub('>', "&#62;")
    end

    def getEncoding
      nls = ENV['NLS_LANG']
      encoding = $1.upcase if nls && nls =~ /^\w+_\w+\.(\w+)$/

      xmlencoding = "US-ASCII"
      if encoding && ENCODING_MAP.has_key?(encoding)
        xmlencoding = ENCODING_MAP[encoding]
      end
      xmlencoding
    end

    def getXML
      ret = ""
      xmlencoding = getEncoding
      ret << "<?xml version=\"1.0\" encoding=\"" + xmlencoding + "\"?>\n"
      ret << "<query-result>\n"
      names = self.getColNames
      elemnames = []
      ret << "  <schema>\n"
      names.each_with_index do |n, i|
        w = @desc[i][0].to_s
        t = @desc[i][1]
        elemnames[i] = nameconv(n)
        if t == 2 || t == 11 || t == 12 || t == 105
          w = nil
        end
        tname = ORACLE_TYPE[t]
        nullok = if @desc[i][6] == 1; "yes" else "no" end
        ret << "    <datatype " +
          "name=\"" + n + "\" " +
          "elemname=\"" + elemnames[i] + "\" " +
          "type=\"" + tname + "\" " +
          (if w; "size=\"" + w + "\" " else "" end) +
          "nullok=\"" + nullok + "\"" +
          "/>\n"
      end
      ret << "  </schema>\n"

      self.fetch do |row|
        ret << "  <row>\n"
        row.each_with_index do |col, i|
          name = elemnames[i]
          if !col.nil?
            ret << "    <" + name + ">" + textconv(col) + "</" + name + ">\n"
          end
        end
        ret << "  </row>\n"
      end
      ret << "</query-result>\n"
      ret
    end

    def getXMLwithID(table)
      ret = ""
      table = nameconv(table)
      xmlencoding = getEncoding
      ret << "<?xml version=\"1.0\" encoding=\"" + xmlencoding + "\"?>\n"
      ret << "<" + table + ">\n"
      names = self.getColNames
      elemnames = []
      ret << "  <schema>\n"
      names.each_with_index do |n, i|
        w = @desc[i][0].to_s
        t = @desc[i][1]
        elemnames[i] = nameconv(n)
        if i == 0
          if t == 11
            next
          else
            raise "cannot find ROWID"
          end
        end
        if t == 2 || t == 11 || t == 12 || t == 105
          w = nil
        end
        tname = ORACLE_TYPE[t]
        nullok = if @desc[i][6] == 1; "yes" else "no" end
        ret << "    <datatype " +
          "name=\"" + n + "\" " +
          "elemname=\"" + elemnames[i] + "\" " +
          "type=\"" + tname + "\" " +
          (if w; "size=\"" + w + "\" " else "" end) +
          "nullok=\"" + nullok + "\"" +
          "/>\n"
      end
      ret << "  </schema>\n"

      self.fetch do |row|
        rowid = ''
        row.each_with_index do |col, i|
          name = elemnames[i]
          if i == 0
            rowid = name + "=\"" + col + "\""
            ret << "  <row " + rowid + ">\n"
            next
          end
          if !col.nil?
            ret << "    <" + name + ">" + textconv(col) + "</" + name + ">\n"
          end
        end
        ret << "  </row>\n"
      end
      ret << "</" + table + ">\n"
      ret
    end
  end
end
