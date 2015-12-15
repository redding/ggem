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

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @kernel_spy = KernelSpy.new
      @stdout = IOSpy.new
      @stderr = IOSpy.new

      @cli = @cli_class.new(@kernel_spy, @stdout, @stderr)
    end
    subject{ @cli }

    should have_imeths :run

    should "know its commands" do
      assert_equal 2, COMMANDS.size

      assert_equal GGem::Gem::CLI, COMMANDS['generate']
      assert_equal GGem::Gem::CLI, COMMANDS['g']
    end

  end

  class RunSetupTests < InitTests
    setup do
      @command_name = Factory.string
      @argv = [ @command_name, Factory.string ]

      @command_class = Class.new
      COMMANDS[@command_name] = @command_class

      @command_spy = CommandSpy.new
      Assert.stub(@command_class, :new).with(@argv){ @command_spy }

      @null_command = GGem::NullCommand.new(@command_name)
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

    should "have output its null commands help" do
      assert_equal @null_command.help, @stdout.read
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

    should "have output that its invalid and its null commands help" do
      exp = "'#{@name}' is not a command.\n\n"
      assert_equal exp, @stderr.read
      assert_equal @null_command.help, @stdout.read
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

    should "have output its null commands help" do
      assert_equal @null_command.help, @stdout.read
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

  class NullCommandTests < UnitTests
    desc "NullCommand"
    setup do
      @name = Factory.string
      @null_command = GGem::NullCommand.new(@name)
    end
    subject{ @null_command }

    should have_readers :name, :argv, :clirb
    should have_imeths :new, :init, :run, :help

    should "know its name, argv and clirb" do
      assert_equal @name, subject.name
      assert_equal [], subject.argv
      assert_instance_of GGem::CLIRB, subject.clirb
    end

    should "set its argv and return itself using `new`" do
      args = [ Factory.string, Factory.string ]
      result = subject.new(args)
      assert_same subject, result
      assert_equal [ @name, args ].flatten, subject.argv
    end

    should "parse its argv when `init`" do
      subject.new([ '--help' ])
      assert_raises(GGem::CLIRB::HelpExit){ subject.init }
      subject.new([ '--version' ])
      assert_raises(GGem::CLIRB::VersionExit){ subject.init }
    end

    should "raise a help exit if its argv is empty when `init`" do
      null_command = GGem::NullCommand.new(nil)
      null_command.new([])
      assert_raises(GGem::CLIRB::HelpExit){ null_command.init }

      null_command = GGem::NullCommand.new("")
      null_command.new([])
      assert_raises(GGem::CLIRB::HelpExit){ null_command.init }
    end

    should "raise an invalid command error when run" do
      assert_raises(GGem::InvalidCommandError){ subject.run }
    end

    should "know its help" do
      exp = "Usage: ggem [COMMAND] [options]\n\n" \
            "Commands: #{COMMANDS.keys.sort.join(', ')}\n" \
            "Options: #{subject.clirb}"
      assert_equal exp, subject.help
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

end
