require 'runit/testcase'
require 'runit/cui/testrunner'

TestCase = RUNIT::TestCase

END {
  suite = RUNIT::TestSuite.new
  if ARGV.size == 0
    to_run  = RUNIT::TestCase.all_suite
  else
    args = ARGV.map { |arg| (arg =~ %r{^/(.*)/$}) ? Regexp.new($1) :  arg}

    #### and this loop becomes a lot simpler using test_methods...

    cases = RUNIT::TestCase.all_suite
    to_run = RUNIT::TestSuite.new
    args.each do |test|
      if test.instance_of?(Regexp) 
	to_run.concat cases.select{|testcase| 
	  test =~ testcase.name
	}
      elsif /^[A-Z]/ =~ test
	to_run.concat cases.select{|testcase| 
	  test == testcase.class.name
	}
      else
	to_run.concat cases.select{|testcase| 
	  test == testcase.method_name
	}
      end
    end
  end
  RUNIT::CUI::TestRunner.run(to_run)
}
