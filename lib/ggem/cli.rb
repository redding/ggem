# frozen_string_literal: true

require "ggem/version"
require "ggem/cli/clirb"
require "ggem/cli/commands"

module GGem; end
class GGem::CLI
  COMMANDS = CommandSet.new{ |unknown| InvalidCommand.new(unknown) }.tap do |c|
    c.add(GenerateCommand, "generate", "g")
    c.add(BuildCommand,    "build",    "b")
    c.add(InstallCommand,  "install",  "i")
    c.add(PushCommand,     "push",     "p")
    c.add(TagCommand,      "tag",      "t")
    c.add(ReleaseCommand,  "release",  "r")
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
      cmd = COMMANDS[cmd_name]
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
    if ENV["DEBUG"]
      @stderr.puts "#{exception.class}: #{exception.message}"
      @stderr.puts exception.backtrace.join("\n")
    end
  end
end
