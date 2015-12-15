require 'ggem/version'
require 'ggem/clirb'

require 'ggem/gem'

module GGem

  class CLI

    COMMANDS = Hash.new{ |h, k| NullCommand.new(k) }.tap do |h|
      h['generate'] = GGem::Gem::CLI
      h['g']        = GGem::Gem::CLI
    end

    def self.run(args)
      self.new.run(args)
    end

    def initialize(kernel = nil, stdout = nil, stderr = nil)
      @kernel = kernel || Kernel
      @stdout = stdout || $stdout
      @stderr = stderr || $stderr
    end

    def run(args)
      begin
        command_name = args.shift
        command = COMMANDS[command_name].new(args)
        command.init
        command.run
      rescue CLIRB::HelpExit
        @stdout.puts command.help
      rescue CLIRB::VersionExit
        @stdout.puts GGem::VERSION
      rescue CLIRB::Error, ArgumentError, InvalidCommandError => exception
        display_debug(exception)
        @stderr.puts "#{exception.message}\n\n"
        @stdout.puts command.help
        @kernel.exit 1
      rescue StandardError => exception
        @stderr.puts "#{exception.class}: #{exception.message}"
        @stderr.puts exception.backtrace.join("\n")
        @kernel.exit 1
      end
      @kernel.exit 0
    end

    private

    def display_debug(exception)
      if ENV['DEBUG']
        @stderr.puts "#{exception.class}: #{exception.message}"
        @stderr.puts exception.backtrace.join("\n")
      end
    end

  end

  class NullCommand
    attr_reader :name, :argv, :clirb

    def initialize(name)
      @name = name
      @argv = []
      @clirb = GGem::CLIRB.new
    end

    def new(args)
      @argv = [ @name, args ].flatten.compact
      self
    end

    def init
      @clirb.parse!(@argv)
      raise CLIRB::HelpExit if @clirb.args.empty? || @name.to_s.empty?
    end

    def run
      raise InvalidCommandError, "'#{self.name}' is not a command."
    end

    def help
      "Usage: ggem [COMMAND] [options]\n\n" \
      "Commands: #{GGem::CLI::COMMANDS.keys.sort.join(', ')}\n" \
      "Options: #{@clirb}"
    end
  end

  InvalidCommandError = Class.new(ArgumentError)

end
