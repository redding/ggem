require 'assert'
require 'ggem/cli'

require 'ggem/gem'
require 'ggem/gemspec'

class GGem::CLI

  class UnitTests < Assert::Context
    desc "GGem::CLI"
    setup do
      @kernel_spy = KernelSpy.new
      @stdout     = IOSpy.new
      @stderr     = IOSpy.new

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
      assert_equal 5, COMMANDS.size

      assert_instance_of InvalidCommand, COMMANDS[Factory.string]

      assert_equal GenerateCommand, COMMANDS['generate']
      assert_equal GenerateCommand, COMMANDS['g']
      assert_equal BuildCommand,    COMMANDS['build']
      assert_equal InstallCommand,  COMMANDS['install']
      assert_equal PushCommand,     COMMANDS['push']
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
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

    should "have run the command" do
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

  class RunWithCommandExitErrorTests < RunSetupTests
    desc "and run with a command that error exits"
    setup do
      Assert.stub(@command_spy, :run){ raise CommandExitError }
      @cli.run(@argv)
    end

    should "have unsuccessfully exited with no stderr output" do
      assert_equal 1, @kernel_spy.exit_status
      assert_empty @stderr.read
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
    should have_imeths :new, :run, :help

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

    should "parse its argv on run" do
      assert_raises(GGem::CLIRB::HelpExit){ subject.new([ '--help' ]).run }
      assert_raises(GGem::CLIRB::VersionExit){ subject.new([ '--version' ]).run }
    end

    should "raise a help exit if its argv is empty" do
      cmd = @command_class.new([nil, ''].choice)
      assert_raises(GGem::CLIRB::HelpExit){ cmd.new([]).run }
    end

    should "raise an invalid command error when run" do
      assert_raises(InvalidCommandError){ subject.new([Factory.string]).run }
    end

    should "know its help" do
      exp = "Usage: ggem [COMMAND] [options]\n\n" \
            "Commands: #{COMMANDS.keys.sort.join(', ')}\n" \
            "Options: #{subject.clirb}"
      assert_equal exp, subject.help
    end

  end

  class IOCommandTests < UnitTests
    setup do
      @stdout, @stderr = IOSpy.new, IOSpy.new
    end
    subject{ @cmd }

  end

  class ValidCommandTests < IOCommandTests
    desc "ValidCommand"
    setup do
      @command_class = Class.new{ include ValidCommand }
      @args = Factory.integer(3).times.map{ Factory.string }
      @cmd  = @command_class.new(@args, @stdout, @stderr)
    end

    should have_imeths :clirb, :run

    should "know its CLI.RB" do
      assert_instance_of GGem::CLIRB, subject.clirb
    end

    should "parse its args when run" do
      subject.run
      assert_equal @args, subject.clirb.args
    end

  end

  class GenerateCommandTests < IOCommandTests
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

    should "be a valid command" do
      assert_kind_of ValidCommand, subject
    end

    should "know its help" do
      exp = "Usage: ggem generate [options] GEM-NAME\n\n" \
            "Options: #{subject.clirb}"
      assert_equal exp, subject.help
    end

    should "save a gem when run" do
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
        cmd.run
      rescue ArgumentError => err
      end

      assert_not_nil err
      exp = "GEM-NAME must be provided"
      assert_equal exp, err.message
      assert_not_empty err.backtrace
    end

  end

  class GemspecCommandTests < IOCommandTests
    desc "GemspecCommand"
    setup do
      @gem1_root_path = TEST_SUPPORT_PATH.join('gem1')
      Assert.stub(Dir, :pwd){ @gem1_root_path}

      @command_class = Class.new{ include GemspecCommand }
      @args = Factory.integer(3).times.map{ Factory.string }
      @cmd  = @command_class.new(@args, @stdout, @stderr)
    end

    should "be a valid, execute command" do
      assert_kind_of ValidCommand,   subject
      assert_kind_of ExecuteCommand, subject
    end

    should "build a new gemspec at the current pwd root" do
      gemspec_new_called_with = nil
      Assert.stub(GGem::Gemspec, :new){ |*args| gemspec_new_called_with = args }

      @command_class.new(@args, @stdout, @stderr)
      assert_equal [Dir.pwd], gemspec_new_called_with
    end

    should "complain if no gemspec file can be found at the current pwd" do
      root = Factory.path
      Assert.stub(Dir, :pwd){ root }

      assert_raises(CommandExitError) do
        @command_class.new(@args, @stdout, @stderr)
      end
      exp = "There are no gemspecs at #{Dir.pwd}\n"
      assert_equal exp, @stderr.read
    end

  end

  class GemspecSpyTests < IOCommandTests
    setup do
      @root_path = Factory.path
      Assert.stub(Dir, :pwd){ @root_path }

      @spec_spy = nil
      Assert.stub(GGem::Gemspec, :new){ |*args| @spec_spy = GemspecSpy.new(*args) }
    end

  end

  class BuildCommandTests < GemspecSpyTests
    desc "BuildCommand"
    setup do
      @command_class = BuildCommand
      @cmd = @command_class.new([], @stdout, @stderr)
    end

    should "be a gemspec command" do
      assert_kind_of GemspecCommand, subject
    end

    should "know its help" do
      exp = "Usage: ggem build [options]\n\n" \
            "Options: #{subject.clirb}\n" \
            "Description:\n" \
            "  Build #{@spec_spy.gem_file_name} into the " \
               "#{GGem::Gemspec::BUILD_TO_DIRNAME} directory"
      assert_equal exp, subject.help
    end

    should "call the spec's run build cmd when run" do
      ENV['DEBUG'] = [nil, '1'].choice
      subject.run

      assert_true @spec_spy.run_build_cmd_called

      exp = ENV['DEBUG'] == '1' ? "build\nbuild cmd was run\n" : ''
      exp += "#{@spec_spy.name} #{@spec_spy.version} built to #{@spec_spy.gem_file}\n"
      assert_equal exp, @stdout.read

      ENV['DEBUG'] = nil
    end

    should "handle cmd errors when run" do
      err_msg = Factory.string
      Assert.stub(@spec_spy, :run_build_cmd){ raise GGem::Gemspec::CmdError, err_msg }

      assert_raises(CommandExitError){ subject.run }
      assert_equal "#{err_msg}\n", @stderr.read
    end

  end

  class InstallCommandTests < GemspecSpyTests
    desc "InstallCommand"
    setup do
      @command_class = InstallCommand
      @cmd = @command_class.new([], @stdout, @stderr)
    end

    should "be a gemspec command" do
      assert_kind_of GemspecCommand, subject
    end

    should "know its help" do
      exp = "Usage: ggem install [options]\n\n" \
            "Options: #{subject.clirb}\n" \
            "Description:\n" \
            "  Build and install #{@spec_spy.gem_file_name} into system gems"
      assert_equal exp, subject.help
    end

    should "call the spec's run build/install cmds when run" do
      ENV['DEBUG'] = [nil, '1'].choice
      subject.run

      assert_true @spec_spy.run_build_cmd_called
      assert_true @spec_spy.run_install_cmd_called

      exp = ENV['DEBUG'] == '1' ? "install\ninstall cmd was run\n" : ''
      exp += "#{@spec_spy.name} #{@spec_spy.version} installed to system gems\n"
      assert_includes exp, @stdout.read

      ENV['DEBUG'] = nil
    end

    should "handle cmd errors when run" do
      err_msg = Factory.string
      Assert.stub(@spec_spy, :run_install_cmd){ raise GGem::Gemspec::CmdError, err_msg }

      assert_raises(CommandExitError){ subject.run }
      assert_equal "#{err_msg}\n", @stderr.read
    end

  end

  class PushCommandTests < GemspecSpyTests
    desc "PushCommand"
    setup do
      @command_class = PushCommand
      @cmd = @command_class.new([], @stdout, @stderr)
    end

    should "be a gemspec command" do
      assert_kind_of GemspecCommand, subject
    end

    should "know its help" do
      exp = "Usage: ggem push [options]\n\n" \
            "Options: #{subject.clirb}\n" \
            "Description:\n" \
            "  Push built #{@spec_spy.gem_file_name} to #{@spec_spy.push_host}"
      assert_equal exp, subject.help
    end

    should "call the spec's run build/push cmds when run" do
      ENV['DEBUG'] = [nil, '1'].choice
      subject.run

      assert_true @spec_spy.run_build_cmd_called
      assert_true @spec_spy.run_push_cmd_called

      exp = ENV['DEBUG'] == '1' ? "push\npush cmd was run\n" : ''
      exp += "#{@spec_spy.name} #{@spec_spy.version} pushed to #{@spec_spy.push_host}\n"
      assert_includes exp, @stdout.read

      ENV['DEBUG'] = nil
    end

    should "handle cmd errors when run" do
      err_msg = Factory.string
      Assert.stub(@spec_spy, :run_push_cmd){ raise GGem::Gemspec::CmdError, err_msg }

      assert_raises(CommandExitError){ subject.run }
      assert_equal "#{err_msg}\n", @stderr.read
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
    attr_reader :run_called

    def initialize
      @run_called = false
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

  class GemspecSpy
    attr_reader :name, :version, :push_host
    attr_reader :run_build_cmd_called, :run_install_cmd_called, :run_push_cmd_called

    def initialize(root_path)
      @root      = Pathname.new(File.expand_path(root_path))
      @name      = Factory.string
      @version   = Factory.string
      @push_host = Factory.url

      @run_build_cmd_called   = false
      @run_install_cmd_called = false
      @run_push_cmd_called    = false
    end

    def path
      @root.join("#{self.name}.gemspec")
    end

    def gem_file_name
      "#{self.name}-#{self.version}.gem"
    end

    def gem_file
      File.join(GGem::Gemspec::BUILD_TO_DIRNAME, self.gem_file_name)
    end

    def run_build_cmd
      @run_build_cmd_called = true
      ['build', 0, 'build cmd was run']
    end

    def run_install_cmd
      @run_install_cmd_called = true
      ['install', 0, 'install cmd was run']
    end

    def run_push_cmd
      @run_push_cmd_called = true
      ['push', 0, 'push cmd was run']
    end

  end

end
