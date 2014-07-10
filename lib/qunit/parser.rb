require 'qunit/logger'

module Qunit
  class Parser

    attr_reader :current_module
    attr_reader :current_test
    attr_reader :unfinished_modules
    attr_reader :failed_assertions
    attr_reader :total_failed
    attr_reader :total_passed
    attr_reader :total
    attr_reader :duration
    attr_reader :logger

    def initialize
      @logger = Qunit::Logger
      @unfinished_modules = Hash.new
      @failed_assertions = Array.new
      @total_failed = 0
      @total_passed = 0
      @total = 0
      @duration = 0
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
      # exit status
      return false, nil
    end

    def module_done(name, *args)
      name ||= "Unnamed Module"
      @unfinished_modules.delete(name.to_sym)
      # exit status
      return false, nil
    end

    def test_start(name)
      prefix = @current_module ? "#{@current_module} - " : ''
      @current_test = "#{prefix}#{name}"
      # exit status
      return false, nil
    end

    def test_done(name, failed, *args)
      if failed > 0
        logger.print 'F', :red
      else
        logger.print '.'
      end
      # exit status
      return false, nil
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
      # exit status
      return false, nil
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
      prefix = ''
      if @current_test
        prefix << "\n[%s]" % @current_test
      elsif @current_module
        prefix << "\n[%s]" % @current_module
      end
      prefix << ' CONSOLE: '
      logger.print prefix, :magenta
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
        # exit status
        return true, 0
      else
        # exit status
        return true, 1
      end
    end

  end
end
