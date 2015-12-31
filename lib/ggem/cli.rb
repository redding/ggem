require 'ggem/version'
require 'ggem/cli/clirb'
require 'ggem/cli/commands'

module GGem

  class CLI

    COMMANDS = Hash.new{ |h, k| InvalidCommand.new(k) }.tap do |h|
      h['generate'] = GenerateCommand
      h['g']        = GenerateCommand
      h['build']    = BuildCommand
      h['b']        = BuildCommand
      h['install']  = InstallCommand
      h['i']        = InstallCommand
      h['push']     = PushCommand
      h['p']        = PushCommand
      h['tag']      = TagCommand
      h['t']        = TagCommand
      h['release']  = ReleaseCommand
      h['r']        = ReleaseCommand
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
        cmd = COMMANDS[cmd_name].new
        cmd.run(args)
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

  end

end
