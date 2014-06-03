require "qunit/runner/version"
require 'shellwords'
require 'open3'
require 'json'

module Qunit
  class Runner
    attr_reader :current_module
    attr_reader :current_test
    attr_reader :unfinished_modules
    attr_reader :failed_assertions
    attr_reader :total_failed
    attr_reader :total_passed
    attr_reader :total
    attr_reader :duration
    attr_reader :should_exit
    attr_reader :exit_status
    attr_reader :test_url

    def initialize(url)
      $stdout.sync = true
      @unfinished_modules = Hash.new
      @failed_assertions = Array.new
      @total_failed = 0
      @total_passed = 0
      @total = 0
      @duration = 0
      @should_exit = false
      @exit_status = 0
      @test_url = url
    end

    def run
      root = File.dirname(File.dirname(__FILE__))
      qunit_bridge = File.join root, 'vendor', 'js', 'qunit_bridge.js'
      phantom_bridge = File.join root, 'vendor', 'js', 'phantom_bridge.js'
      opts = {
        timeout: 10000,
        inject: qunit_bridge
      }
      cmd = Shellwords.join [
        'phantomjs',
        phantom_bridge,
        '/dev/stdout',
        @test_url,
        opts.to_json
      ]
      print_banner
      Open3.popen3(cmd) do |i, o, e, t|
        i.close
        begin
          while line = o.gets and !@should_exit
            parse line
          end
          safe_kill t.pid
        rescue Exception
          safe_kill t.pid
          raise
        end
      end
      exit @exit_status
    end

    def safe_kill(pid)
      begin
        Process.kill("KILL", pid)
        true
      rescue
        false
      end
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
        print 'F'.red
      else
        print '.'
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
      puts "PhantomJS unable to load #{url} URI".red
      @total_failed += 1
      @total += 1
      log_summary
    end

    def fail_timeout
      puts "PhantomJS timed out.".red
      @total_failed += 1
      @total += 1
      log_summary
    end

    def console(message)
      puts "#{'CONSOLE: '.magenta} #{message}"
    end

    def print_banner
      puts "Starting tests at url #{@test_url}"
    end

    def log_summary
      puts ''
      @failed_assertions.each do |assertion|
        puts assertion[:name]
        puts "Message: #{assertion[:message]}".red
        if assertion[:actual] != assertion[:expected]
          puts "Actual: #{assertion[:actual]}".magenta
          puts "Expected: #{assertion[:expected]}".yellow
        end
        if assertion[:source]
          puts assertion[:source].cyan
        end
        puts ''
      end
      if @total == 0
        puts "0/0 assertions ran (#{@duration/1000.0}s)".magenta
      else
        puts "#{@total_passed}/#{@total} assertions passed (#{@duration/1000.0}s)"
      end
      if @total_failed == 0 and @total > 0
        puts "OK".green
        @should_exit = true
        @exit_status = 0
      else
        @should_exit = true
        @exit_status = 1
      end
    end

  end
end

