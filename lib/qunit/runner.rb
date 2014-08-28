require "qunit/runner/version"
require 'qunit/logger'
require 'qunit/parser'
require 'shellwords'
require 'open3'
require 'json'
require 'colorize'

module Qunit
  class Runner
    attr_reader :should_exit
    attr_reader :exit_status
    attr_reader :test_url
    attr_reader :logger

    def initialize(url)
      $stdout.sync = true
      @should_exit = false
      @exit_status = 0
      @test_url = url
      @logger = Qunit::Logger
      @parser = Qunit::Parser.new
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
        '--load-images=false',
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
            @should_exit, @exit_status = @parser.parse line
          end
          safe_kill t.pid
        rescue Exception
          safe_kill t.pid
          raise
        end
      end
      exit @exit_status || 1
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
      logger.puts "Starting tests at url %s" % @test_url
    end

  end
end
