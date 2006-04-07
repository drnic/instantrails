require 'fox14'
require 'ostruct'

module Fox
  
  class FXApp

    alias addTimeoutOrig addTimeout # :nodoc:
    alias removeTimeoutOrig removeTimeout # :nodoc:
    alias remainingTimeoutOrig remainingTimeout # :nodoc:

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
    # A second form of #addTimeout takes a Method instance as its second
    # argument:
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
    # All of these return a reference to an object that can be passed to
    # #removeTimeout if it is necessary to remove the timeout before it fires.
    #
    def addTimeout(ms, *args, &block)
      tgt, sel, ptr = nil, 0, nil
      if args.length > 0
        if args[0].respond_to? :call
          tgt = FXPseudoTarget.new
	  tgt.pconnect(SEL_TIMEOUT, args[0], nil)
        else # it's some other kind of object
          tgt, sel = args[0], args[1]
        end
      else
        tgt = FXPseudoTarget.new
	tgt.pconnect(SEL_TIMEOUT, nil, block)
      end
      addTimeoutOrig(tgt, sel, ms, ptr)
      OpenStruct.new({ "tgt" => tgt, "sel" => sel })
    end
  
    #
    # Remove timeout.
    #
    def removeTimeout(timer)
      removeTimeoutOrig(timer.tgt, timer.sel)
    end
  
    #
    # Return +true+ if given timeout has been set, otherwise return +false+.
    #
    def hasTimeout?(timer)
      hasTimeout(timer.tgt, timer.sel)
    end
  
    #
    # Return the time remaining (in milliseconds) until the given timer fires.
    # If the timer is past due, zero is returned.  If there is no such
    # timer, infinity (UINT_MAX) is returned.
    #
    def remainingTimeout(timer)
      remainingTimeoutOrig(timer.tgt, timer.sel)
    end
  end
 end
