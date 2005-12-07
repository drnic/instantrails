require 'fox12'

module Fox
  class FXApp

    alias addTimeoutOrig addTimeout # :nodoc:

    #
    # Register a timeout message to be sent to a target object;
    # the timer fires only once after the interval expires.
    #
    # There are several forms for #addTimeout; the original form (from FOX)
    # takes three arguments:
    #
    #   anApp.addTimeout(aDelay, anObject, aMessageId)
    #
    # Here, _aDelay_ is the time interval (in milliseconds) to wait
    # before firing this timeout. The second and third arguments are the
    # target object and message identifier for the message to be sent when
    # this timeout fires.
    #
    # A second form of #addTimeout takes a Method instance as its single argument:
    #
    #   anApp.addTimeout(aDelay, aMethod)
    #
    # For this form, the method should have the standard argument list
    # for a FOX message handler. That is, the method should take three
    # arguments, for the message _sender_ (an FXObject), the message _selector_,
    # and the message _data_ (if any).
    #
    # The last form of #addTimeout takes a block:
    #
    #   anApp.addTimeout(aDelay) { |sender, sel, data|
    #     ... handle the chore ...
    #   }
    #
    # All of these return a reference to an opaque FXTimer instance that
    # can be passed to #removeTimeout if it is necessary to remove the timeout
    # before it fires.
    #
    def addTimeout(ms, *args, &block)
      tgt, sel = nil, 0
      if args.length > 0
        if args[0].respond_to? :call
          tgt = FXPseudoTarget.new
	  tgt.pconnect(SEL_TIMEOUT, args[0], nil)
        else # it's some other kind of object
          tgt = args[0]
          sel = args[1]
        end
      else
        tgt = FXPseudoTarget.new
	tgt.pconnect(SEL_TIMEOUT, nil, block)
      end
      addTimeoutOrig(tgt, sel, ms)
    end
  end
end
