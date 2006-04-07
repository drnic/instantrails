require 'tmpdir'

module RRB

  CONF = {
    'WORK_DIR_BASENAME' => "#{Dir.tmpdir}/rrb_work",
    'TAB_WIDTH' => 8,
    'INDENT_LEVEL' => 2,
    'RUBY_OPTS' => "-I#{$:.join(':')}" # make sure we use FreeRIDE rrb
  }
  
  begin
    load File.join( ENV["HOME"], ".rrbrc" )
  rescue LoadError
  end
  
  WORK_DIR_BASENAME = CONF["WORK_DIR_BASENAME"]
  TAB_WIDTH = CONF["TAB_WIDTH"]
  INDENT_LEVEL = CONF["INDENT_LEVEL"]
  RUBY_OPTS = CONF["RUBY_OPTS"]
end
