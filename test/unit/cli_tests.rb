require 'assert'
require 'ggem/cli'

require 'ggem/gem'

class GGem::CLI

  class UnitTests < Assert::Context
    desc "GGem::CLI"
    setup do
      @cli_class = GGem::CLI
    end
    subject{ @cli_class }

    should have_imeths :run

    should "build and run an instance of itself using `run`" do
      cli_spy = CLISpy.new
      Assert.stub(subject, :new).with{ cli_spy }

      args = [Factory.string]
      subject.run(args)
      assert_equal args, cli_spy.run_called_with
    end

    should "know its commands" do
      assert_equal 2, COMMANDS.size

      assert_instance_of InvalidCommand, COMMANDS[Factory.string]

      assert_equal GenerateCommand, COMMANDS['generate']
      assert_equal GenerateCommand, COMMANDS['g']
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @kernel_spy = KernelSpy.new
      @stdout     = IOSpy.new
      @stderr     = IOSpy.new

      @cli = @cli_class.new(@kernel_spy, @stdout, @stderr)
    end
    subject{ @cli }

    should have_imeths :run

  end

  class RunSetupTests < InitTests
    setup do
      @command_name = Factory.string
      @argv = [@command_name, Factory.string]

      @command_class = Class.new
      COMMANDS[@command_name] = @command_class

      @command_spy = CommandSpy.new
      Assert.stub(@command_class, :new).with(@argv){ @command_spy }

      @invalid_command = InvalidCommand.new(@command_name)
    end
    teardown do
      COMMANDS.delete(@command_name)
    end

  end

  class RunTests < RunSetupTests
    desc "and run"
    setup do
      @cli.run(@argv)
    end

    should "have init and run the command" do
      assert_true @command_spy.init_called
      assert_true @command_spy.run_called
    end

    should "have successfully exited" do
      assert_equal 0, @kernel_spy.exit_status
    end

  end

  class RunWithNoArgsTests < RunSetupTests
    desc "and run with no args"
    setup do
      @cli.run([])
    end

    should "output the invalid command's help" do
      assert_equal @invalid_command.help, @stdout.read
      assert_empty @stderr.read
    end

    should "have successfully exited" do
      assert_equal 0, @kernel_spy.exit_status
    end

  end

  class RunWithInvalidCommandTests < RunSetupTests
    desc "and run with an invalid command"
    setup do
      @name = Factory.string
      @argv.unshift(@name)
      @cli.run(@argv)
    end

    should "output that it is invalid and output the invalid command's help" do
      exp = "'#{@name}' is not a command.\n\n"
      assert_equal exp, @stderr.read
      assert_equal @invalid_command.help, @stdout.read
    end

    should "have unsuccessfully exited" do
      assert_equal 1, @kernel_spy.exit_status
    end

  end

  class RunWithHelpTests < RunSetupTests
    desc "and run with the help switch"
    setup do
      @cli.run([ '--help' ])
    end

    should "output the invalid command's help" do
      assert_equal @invalid_command.help, @stdout.read
      assert_empty @stderr.read
    end

    should "have successfully exited" do
      assert_equal 0, @kernel_spy.exit_status
    end

  end

  class RunWithVersionTests < RunSetupTests
    desc "and run with the version switch"
    setup do
      @cli.run([ '--version' ])
    end

    should "have output its version" do
      assert_equal "#{GGem::VERSION}\n", @stdout.read
      assert_empty @stderr.read
    end

    should "have successfully exited" do
      assert_equal 0, @kernel_spy.exit_status
    end

  end

  class RunWithErrorTests < RunSetupTests
    setup do
      @exception = RuntimeError.new(Factory.string)
      Assert.stub(@command_class, :new).with(@argv){ raise @exception }
      @cli.run(@argv)
    end

    should "have output an error message" do
      exp = "#{@exception.class}: #{@exception.message}\n" \
            "#{@exception.backtrace.join("\n")}\n"
      assert_equal exp, @stderr.read
      assert_empty @stdout.read
    end

    should "have unsuccessfully exited" do
      assert_equal 1, @kernel_spy.exit_status
    end

  end

  class InvalidCommandTests < UnitTests
    desc "InvalidCommand"
    setup do
      @name = Factory.string
      @command_class = InvalidCommand
      @cmd = @command_class.new(@name)
    end
    subject{ @cmd }

    should have_readers :name, :argv, :clirb
    should have_imeths :new, :init, :run, :help

    should "know its attrs" do
      assert_equal @name, subject.name
      assert_equal [],    subject.argv

      assert_instance_of GGem::CLIRB, subject.clirb
    end

    should "set its argv and return itself using `new`" do
      args = [Factory.string, Factory.string]
      result = subject.new(args)
      assert_same subject, result
      assert_equal [@name, args].flatten, subject.argv
    end

    should "parse its argv when `init`" do
      subject.new([ '--help' ])
      assert_raises(GGem::CLIRB::HelpExit){ subject.init }
      subject.new([ '--version' ])
      assert_raises(GGem::CLIRB::VersionExit){ subject.init }
    end

    should "raise a help exit if its argv is empty when `init`" do
      cmd = @command_class.new(nil)
      cmd.new([])
      assert_raises(GGem::CLIRB::HelpExit){ cmd.init }

      cli = @command_class.new("")
      cli.new([])
      assert_raises(GGem::CLIRB::HelpExit){ cli.init }
    end

    should "raise an invalid command error when run" do
      assert_raises(InvalidCommandError){ subject.run }
    end

    should "know its help" do
      exp = "Usage: ggem [COMMAND] [options]\n\n" \
            "Commands: #{COMMANDS.keys.sort.join(', ')}\n" \
            "Options: #{subject.clirb}"
      assert_equal exp, subject.help
    end

  end

  class GenerateCommandTests < UnitTests
    desc "GenerateCommand"
    setup do
      @name = Factory.string

      @path = Factory.dir_path
      Assert.stub(Dir, :pwd){ @path }

      @gem_new_called_with = []
      @gem_spy = GemSpy.new
      @gem_class = GGem::Gem
      Assert.stub(@gem_class, :new) do |*args|
        @gem_new_called_with = args
        @gem_spy
      end

      @stdout = IOSpy.new
      @command_class = GenerateCommand
      @cmd = @command_class.new([@name], @stdout)
    end
    subject{ @cmd }

    should have_readers :clirb

    should "know its CLI.RB" do
      assert_instance_of GGem::CLIRB, subject.clirb
    end

    should "know its help" do
      exp = "Usage: ggem generate [options] GEM-NAME\n\n" \
            "Options: #{subject.clirb}"
      assert_equal exp, subject.help
    end

    should "parse its args when `init`" do
      subject.init
      assert_equal [@name], subject.clirb.args
    end

    should "init and save a gem when run" do
      subject.init
      subject.run

      assert_equal [@path, @name], @gem_new_called_with
      assert_true @gem_spy.save_called

      exp = "created gem and initialized git repo in #{@gem_spy.path}\n"
      assert_equal exp, @stdout.read
    end

    should "re-raise a specific argument error on gem 'no name' errors" do
      Assert.stub(@gem_class, :new) { raise GGem::Gem::NoNameError }
      err = nil
      begin
        cmd = @command_class.new([])
        cmd.init
        cmd.run
      rescue ArgumentError => err
      end

      assert_not_nil err
      exp = "GEM-NAME must be provided"
      assert_equal exp, err.message
      assert_not_empty err.backtrace
    end

  end

  class CLISpy
    attr_reader :run_called_with

    def initialize
      @run_called_with = nil
    end

    def run(args)
      @run_called_with = args
    end
  end

  class CommandSpy
    attr_reader :init_called, :run_called

    def initialize
      @init_called = false
      @run_called = false
    end

    def init
      @init_called = true
    end

    def run
      @run_called = true
    end

    def help
      Factory.text
    end
  end

  class KernelSpy
    attr_reader :exit_status

    def initialize
      @exit_status = nil
    end

    def exit(code)
      @exit_status ||= code
    end
  end

  class IOSpy
    def initialize
      @io = StringIO.new
    end

    def puts(message)
      @io.puts message
    end

    def read
      @io.rewind
      @io.read
    end
  end

  class GemSpy
    attr_reader :save_called

    def initialize
      @save_called = false
    end

    def save!
      @save_called = true
      self
    end

    def path
      @path ||= Factory.path
    end
  end

end
