require 'fox12'

module Fox
  class FXApp

    alias addChoreOrig addChore # :nodoc:

    #
    # Add a idle processing message to be sent to a target object when
    # the system becomes idle, i.e. when there are no more events to be processed.
    # There are several forms for #addChore; the original form (from FOX)
    # takes two arguments, a target object and a message identifier:
    #
    #   anApp.addChore(anObject, aMessageId)
    #
    # A second form takes a Method instance as its single argument:
    #
    #   anApp.addChore(aMethod)
    #
    # For this form, the method should have the standard argument list
    # for a FOX message handler. That is, the method should take three
    # arguments, for the message _sender_ (an FXObject), the message _selector_,
    # and the message _data_ (if any).
    #
    # The last form takes a block:
    #
    #   anApp.addChore() { |sender, sel, data|
    #     ... handle the chore ...
    #   }
    #
    # All of these return a reference to an opaque FXChore instance that
    # can be passed to #removeChore if it is necessary to remove the chore
    # before it fires.
    #
    def addChore(*args, &block)
      tgt, sel = nil, 0
      if args.length > 0
        if args[0].respond_to? :call
          tgt = FXPseudoTarget.new
	  tgt.pconnect(SEL_CHORE, args[0], block)
        else
	  tgt, sel = args[0], args[1]
        end
      else
        tgt = FXPseudoTarget.new
	tgt.pconnect(SEL_CHORE, nil, block)
      end
      addChoreOrig(tgt, sel)
    end
  end
end
