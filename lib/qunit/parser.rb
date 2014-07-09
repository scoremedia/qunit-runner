require 'qunit/logger'

module Qunit
  class Parser

    attr_reader :logger

    def initialize
      @logger = Qunit::Logger
    end

    def parse(line)
      params = JSON.parse line
      event = params.shift
      case event
      when 'qunit.moduleStart'
        module_start *params
      when 'qunit.moduleDone'
        module_done *params
      when 'qunit.testStart'
        test_start *params
      when 'qunit.testDone'
        test_done *params
      when 'qunit.log'
        qunit_log *params
      when 'qunit.done'
        qunit_done *params
      when 'fail.load'
        fail_load *params
      when 'fail.timeout'
        fail_timeout *params
      when 'console'
        console *params
      end
    end

    def module_start(name)
      name ||= "Unnamed Module"
      @unfinished_modules[name.to_sym] = true
      @current_module = name
    end

    def module_done(name, *args)
      name ||= "Unnamed Module"
      @unfinished_modules.delete(name.to_sym)
    end

    def test_start(name)
      prefix = @current_module ? "#{@current_module} - " : ''
      @current_test = "#{prefix}#{name}"
    end

    def test_done(name, failed, *args)
      if failed > 0
        logger.print 'F', :red
      else
        logger.print '.'
      end
    end

    def qunit_log(result, actual, expected, message, source)
      if not result
        assertion = {
          name: @current_test,
          actual: actual,
          expected: expected,
          message: message,
          source: source
        }
        @failed_assertions.push assertion
      end
    end

    def qunit_done(failed, passed, total, duration)
      @total_failed += failed
      @total_passed += passed
      @total += total
      @duration += duration
      log_summary
    end

    def fail_load(url)
      logger.puts "PhantomJS unable to load #{url} URI", :red
      @total_failed += 1
      @total += 1
      log_summary
    end

    def fail_timeout
      logger.puts "PhantomJS timed out.", :red
      @total_failed += 1
      @total += 1
      log_summary
    end

    def console(message)
      logger.print 'CONSOLE:', :magenta
      logger.print message
      logger.print "\n"
    end

    def log_summary
      logger.puts ''
      @failed_assertions.each do |assertion|
        logger.puts assertion[:name]
        logger.puts "Message: #{assertion[:message]}", :red
        if assertion[:actual] != assertion[:expected]
          logger.puts "Actual: #{assertion[:actual]}", :magenta
          logger.puts "Expected: #{assertion[:expected]}", :yellow
        end
        if assertion[:source]
          logger.puts assertion[:source], :cyan
        end
        logger.puts ''
      end
      if @total == 0
        logger.puts "0/0 assertions ran (#{@duration/1000.0}s)", :magenta
      else
        logger.puts "#{@total_passed}/#{@total} assertions passed (#{@duration/1000.0}s)"
      end
      if @total_failed == 0 and @total > 0
        logger.puts "OK", :green
        @should_exit = true
        @exit_status = 0
      else
        @should_exit = true
        @exit_status = 1
      end
    end

  end
end
