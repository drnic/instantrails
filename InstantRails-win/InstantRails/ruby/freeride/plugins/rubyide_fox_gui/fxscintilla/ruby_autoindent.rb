# FreeRIDE Ruby Integrated Development Environment
#
# Author: Rich Kilmer
# Copyright (c) 2001, Richard Kilmer, rich@infoether.com
# Licensed under the Ruby License

module AutoIndent
  NO_INDENT = 0
  START_INDENT = 1
  START_END_INDENT = 2
  END_INDENT = 3
  
  def automatic_indentation(ch)
    if (ch==10 or ch==13)
      sel_start = @model.selection_start
      sel_end = @model.selection_end
      current_line = @model.line_from_position(@model.current_pos)
      indent = current_line > 0 ? @model.get_line_indentation(current_line - 1) : 0
      set_line_indentation(current_line, indent)
    end
  end

=begin
  def automatic_indentation(ch)
    sel_start = @model.selection_start
    sel_end = @model.selection_end
    current_line = @model.line_from_position(@model.current_pos)
    indent_size = @model.properties["indent.size"]
    if (ch==10 or ch==13)
      indent, state = get_indent_state(current_line - 1)
      #fold_level = (current_line > 0 ? @model.get_fold_level(current_line - 1) & Scintilla::SC_FOLDLEVELNUMBERMASK : Scintilla::Scintilla::SC_FOLDLEVELBASE)
      case state
        when START_INDENT
          indent = indent + indent_size
          #@model.set_fold_level(current_line - 1, foldLevel|Scintilla::SC_FOLDLEVELHEADERFLAG)
          #fold_level = fold_level + 1
        when END_INDENT
          back_line = current_line - 2
          while back_line > -1
            indent2, state2 = get_indent_state(back_line)
            if state2==START_INDENT
              set_line_indentation(current_line-1, indent2)
              indent = indent2
              break;
            elsif state2==END_INDENT
              indent2 = indent2 - indent_size
              set_line_indentation(current_line-1, indent2)
              indent=indent2
              break;
            end
            back_line = back_line - 1
          end
        when START_END_INDENT
          back_line = current_line-2
          while back_line > -1
            indent2, state2 = get_indent_state(back_line)
            if state2==START_INDENT or state2==START_END_INDENT
              set_line_indentation(current_line-1, indent2)
              indent=indent2 + indent_size
              #@model.set_fold_level(current_line - 1, @model.get_fold_level(back_line)|Scintilla::SC_FOLDLEVELHEADERFLAG)
              #fold_level = fold_level + 1
              break;
            end
            back_line = back_line - 1
          end
      end
      #@model.set_fold_level(current_line, fold_level)
      #puts "fold: #{@model.get_fold_level(current_line)} prev: #{@model.get_fold_level(current_line-1) if current_line > 0}"
      set_line_indentation(current_line, indent)
    end
  end
=end
  
  
  def get_indent_state(line)
    state = NO_INDENT
    indent = line > 0 ? @model.get_line_indentation(line) : 0
    text = @model.get_line(line)
    each_indent_token(text) do |token|
      case token[0..((token.index(/[\s(]/).nil? ? 0 : token.index(/[\s(]/) )-1)]
      when "def", "case", "class", "while", "until", "module", "catch"
        state=START_INDENT
      when "unless", "if","begin"
        state=START_INDENT unless token[-3..-1] == "end"
      when "when", "else", "elsif","rescue","ensure"
        state = START_END_INDENT
      when "end", "}"
        if state==START_INDENT
         state = NO_INDENT
        else
         state = END_INDENT
        end
      else
         state = START_INDENT if (token[-2..-1]=="do" && token[-3..-1]!="end") or token[-1..-1]=="{" or token[-1..-1]=="|"
      end
    end

    return indent, state
  end

  def each_indent_token(line)
    in_str = false
    str_chr = nil
    result = ""
    line.each_byte do |c|
      case c
      when 35 #  35=#
        unless in_str
          yield result.strip
          return
        end
      when 39 # 39='
        if in_str
          if str_chr==c
            in_str=false
          end
        else
          in_str = true
          str_chr = c
        end
      when 34 # 34="
        if in_str
          if str_chr==c
            in_str=false unless result[-1]==92
          end
        else
          in_str = true
          str_chr = c
        end
      when 59 #  59=;
        yield result.strip
        result=""
      end
      result += c.chr if c!=59
    end
    yield result.strip
  end

  def set_line_indentation(line, indent)
    #puts "line: #{line} indent: #{indent}"
    return if indent < 0
    sel_start = @model.selection_start
    sel_end = @model.selection_end
    pos_before = @model.get_line_indent_position(line)
    @model.set_line_indentation(line, indent)
    pos_after = @model.get_line_indent_position(line)
    pos_diff = pos_after - pos_before
    if pos_after > pos_before
      if sel_start >= pos_before
        sel_start = sel_start + pos_diff
      end
      if sel_end >= pos_before
        sel_end = sel_end + pos_diff
      end
    elsif pos_after < pos_before
      if sel_start >= pos_after
        if sel_start >= pos_before
          sel_start = sel_start + pos_diff
        else
          sel_start = pos_after
        end
      end
      if sel_end >= pos_after
        if sel_end >= pos_before
          sel_end = sel_end + pos_diff
        else
          sel_end = pos_after
        end
      end
    end
    @model.set_sel(sel_start, sel_end)
  end

end