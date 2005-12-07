require 'ripper.rb'
require 'rubyide_tools_source_parser/source_structures'
require 'rubyide_tools_source_parser/simple_parser'

module FreeRIDE
  module Tools
    
    ##
    # This creates a parser for an editpane.  Its function (to parse the source) is
    # available by calling editpane.manager.parse_text
    #
    class SourceParser
      extend FreeBASE::StandardPlugin
      
      def SourceParser.start(plugin)
        plugin["/system/ui/components/EditPane"].subscribe do |event, slot|
          if (event == :notify_slot_add && slot.parent.name == 'EditPane')
            SourceParser.new(plugin, slot)
          end
        end
        plugin.transition(FreeBASE::RUNNING)
      end
      
      def initialize(plugin, slot)
        @slot = slot
        @plugin = plugin
        @parser = SimpleParser.new
        @slot['actions/parse_code'].set_proc method(:parse_code)
      end
      
      def parse_code(text)
        return nil unless text
        begin
          source = @parser.parse_string(text)
        rescue
          source = nil
        ensure
          @parser.clear
        end
        source
      end
    end
    
  end
end
