require "qunit/runner/version"
require 'qunit/logger'
require 'qunit/parser'
require 'shellwords'
require 'open3'
require 'json'
require 'colorize'

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

    def run(load_timeout = 10000)
      root = File.dirname(File.dirname(__FILE__))
      qunit_bridge = File.join root, 'vendor', 'js', 'qunit_bridge.js'
      phantom_bridge = File.join root, 'vendor', 'js', 'phantom_bridge.js'
      opts = {
        timeout: load_timeout,
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

    protected

    def print_banner
      logger.puts "Starting tests at url %" % @test_url
    end

  end
end
