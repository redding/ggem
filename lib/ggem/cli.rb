require 'ggem/version'
require 'ggem/clirb'

module GGem

  class CLI

    class InvalidCommand;  end
    class GenerateCommand; end
    COMMANDS = Hash.new{ |h, k| InvalidCommand.new(k) }.tap do |h|
      h['generate'] = GenerateCommand
      h['g']        = GenerateCommand
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
        cmd_name = args.shift
        cmd = COMMANDS[cmd_name].new(args)
        cmd.run
      rescue CLIRB::HelpExit
        @stdout.puts cmd.help
      rescue CLIRB::VersionExit
        @stdout.puts GGem::VERSION
      rescue CLIRB::Error, ArgumentError, InvalidCommandError => exception
        display_debug(exception)
        @stderr.puts "#{exception.message}\n\n"
        @stdout.puts cmd.help
        @kernel.exit 1
      rescue CommandExitError
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

    InvalidCommandError = Class.new(ArgumentError)
    CommandExitError    = Class.new(RuntimeError)

    class InvalidCommand

      attr_reader :name, :argv, :clirb

      def initialize(name)
        @name  = name
        @argv  = []
        @clirb = GGem::CLIRB.new
      end

      def new(args)
        @argv = [@name, args].flatten.compact
        self
      end

      def run
        @clirb.parse!(@argv)
        raise CLIRB::HelpExit if @clirb.args.empty? || @name.to_s.empty?
        raise InvalidCommandError, "'#{self.name}' is not a command."
      end

      def help
        "Usage: ggem [COMMAND] [options]\n\n" \
        "Commands: #{COMMANDS.keys.sort.join(', ')}\n" \
        "Options: #{@clirb}"
      end

    end

    class GenerateCommand

      attr_reader :clirb

      def initialize(argv, stdout = nil)
        @argv   = argv
        @stdout = stdout || $stdout
        @clirb  = GGem::CLIRB.new
      end

      def run
        @clirb.parse!(@argv)
        require 'ggem/gem'
        path = GGem::Gem.new(Dir.pwd, @clirb.args.first).save!.path
        @stdout.puts "created gem and initialized git repo in #{path}"
      rescue GGem::Gem::NoNameError => exception
        error = ArgumentError.new("GEM-NAME must be provided")
        error.set_backtrace(exception.backtrace)
        raise error
      end

      def help
        "Usage: ggem generate [options] GEM-NAME\n\n" \
        "Options: #{@clirb}"
      end

    end

  end

end
