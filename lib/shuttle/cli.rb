require 'optparse'

module Shuttle
  class CLI
    attr_reader :options, :command
    attr_reader :path

    def initialize(path=nil)
      @path    = File.expand_path(path || Dir.pwd)
      @options = default_options
    end

    def run
      parse_options
      parse_command
      find_config

      begin
        runner = Shuttle::Runner.new(@options)
        runner.execute(@command.dup)
      rescue Shuttle::ConfigError => err
        terminate(err.message)
      end
    end

    def terminate(message, status=1)
      STDERR.puts(message)
      exit(status)
    end

    def default_options
      {
        :path   => nil,
        :target => 'production',
        :log    => false
      }
    end

    def parse_options
      parser = OptionParser.new do |opts|
        opts.on('-v', '--version', 'Show version') do
          puts "Shuttle version #{Shuttle::VERSION}"
          exit 0
        end

        opts.on('-e', '--environment NAME', 'Deployment target environment') do |v|
          @options[:target] = v
        end

        opts.on('-d', '--debug', 'Enable debugging') do
          @options[:log] = true
        end

        opts.on('-f', '--file PATH', 'Configuration file path') do |v|
          @options[:path] = v
        end
      end

      begin
        parser.parse!
      rescue OptionParser::ParseError => e
        terminate(e.message)
      end
    end

    def parse_command
      case ARGV.size
      when 0
        terminate("Command required")
      when 1
        @command = ARGV.shift
      when 2
        @options[:target] = ARGV.shift
        @command = ARGV.shift
      else
        terminate("Maximum of 2 arguments allowed")
      end
    end

    def find_config
      return if try_config("#{@path}/shuttle.yml")
      return if try_config("#{@path}/config/deploy.yml")
      return if try_config("#{ENV['HOME']}/.shuttle/#{File.basename(Dir.pwd)}.yml")

      if @options[:path].nil?
        terminate("Please provide config with -f option.")
      end
    end

    def try_config(path)
      if File.exists?(path)
        @options[:path] = path
        return true
      end

      false
    end
  end
end