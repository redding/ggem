# frozen_string_literal: true

require "assert"
require "ggem/cli"

require "ggem/cli/clirb"
require "ggem/cli/commands"
require "ggem/gem"
require "ggem/gemspec"
require "ggem/git_repo"
require "much-plugin"

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
      assert_equal 6, COMMANDS.size

      assert_instance_of InvalidCommand, COMMANDS[Factory.string]

      assert_instance_of GenerateCommand, COMMANDS["generate"]
      assert_instance_of BuildCommand,    COMMANDS["build"]
      assert_instance_of InstallCommand,  COMMANDS["install"]
      assert_instance_of PushCommand,     COMMANDS["push"]
      assert_instance_of TagCommand,      COMMANDS["tag"]
      assert_instance_of ReleaseCommand,  COMMANDS["release"]

      assert_same COMMANDS["generate"], COMMANDS["g"]
      assert_same COMMANDS["build"],    COMMANDS["b"]
      assert_same COMMANDS["install"],  COMMANDS["i"]
      assert_same COMMANDS["push"],     COMMANDS["p"]
      assert_same COMMANDS["tag"],      COMMANDS["t"]
      assert_same COMMANDS["release"],  COMMANDS["r"]
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
      @command_spy   = CommandSpy.new
      Assert.stub(@command_class, :new){ @command_spy }
      COMMANDS.add(@command_class, @command_name)

      @invalid_command = InvalidCommand.new(@command_name)
    end
    teardown do
      COMMANDS.remove(@command_name)
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
      exp = "`#{@name}` is not a command.\n\n"
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
      @cli.run([ "--help" ])
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
      @cli.run([ "--version" ])
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
      Assert.stub(@command_spy, :run){ raise @exception }
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

    should have_readers :name, :clirb
    should have_imeths :new, :run, :help

    should "know its attrs" do
      assert_equal @name, subject.name
      assert_instance_of CLIRB, subject.clirb
    end

    should "set its argv and return itself using `new`" do
      assert_same subject, subject.new
    end

    should "parse its argv on run" do
      assert_raises(CLIRB::HelpExit){ subject.new.run([ "--help" ]) }
      assert_raises(CLIRB::VersionExit){ subject.new.run([ "--version" ]) }
    end

    should "raise a help exit if its name is empty" do
      cmd = @command_class.new([nil, ""].sample)
      argv = [Factory.string, Factory.string]
      assert_raises(CLIRB::HelpExit){ cmd.new.run(argv) }
    end

    should "raise an invalid command error when run" do
      assert_raises(InvalidCommandError){ subject.new.run([Factory.string]) }
    end

    should "know its help" do
      exp = "Usage: ggem [COMMAND] [options]\n\n" \
            "Options: #{subject.clirb}\n" \
            "Commands:\n" \
            "#{COMMANDS.to_s.split("\n").map{ |l| "  #{l}" }.join("\n")}\n"
      assert_equal exp, subject.help
    end
  end

  class IOCommandTests < UnitTests
    setup do
      @argv = [Factory.string]
      @stdout, @stderr = IOSpy.new, IOSpy.new
    end
    subject{ @cmd }
  end

  class ValidCommandTests < IOCommandTests
    desc "ValidCommand"
    setup do
      @command_class = Class.new{ include ValidCommand }
      @cmd = @command_class.new
    end

    should have_imeths :clirb, :run, :summary

    should "know its CLI.RB" do
      assert_instance_of CLIRB, subject.clirb
    end

    should "parse its args when run" do
      argv = Factory.integer(3).times.map{ Factory.string }
      subject.run(argv, @stdout, @stderr)
      assert_equal argv, subject.clirb.args
    end

    should "take custom CLIRB build procs" do
      cmd = @command_class.new do
        option "test", "testing", :abbrev => "t"
      end
      cmd.run(["-t"], @stdout, @stderr)
      assert_true cmd.clirb.opts["test"]
    end

    should "default its summary" do
      assert_equal "", subject.summary
    end
  end

  class GitRepoCommandTests < IOCommandTests
    desc "GitRepoCommand"
    setup do
      @gem1_root_path = TEST_SUPPORT_PATH.join("gem1")
      Assert.stub(Dir, :pwd){ @gem1_root_path}

      @command_class = Class.new{ include GitRepoCommand }
      @cmd = @command_class.new
    end

    should "be a valid, notify cmd command" do
      assert_kind_of ValidCommand,     subject
      assert_kind_of NotifyCmdCommand, subject
    end

    should "build a new git repo at the current pwd root" do
      gitrepo_new_called_with = nil
      Assert.stub(GGem::GitRepo, :new){ |*args| gitrepo_new_called_with = args }

      @command_class.new
      assert_equal [Dir.pwd], gitrepo_new_called_with
    end
  end

  module RootPathTests
    include MuchPlugin

    plugin_included do
      setup do
        @root_path = Factory.path
        Assert.stub(Dir, :pwd){ @root_path }
      end
    end
  end

  module GitRepoSpyTests
    include MuchPlugin

    plugin_included do
      include RootPathTests

      setup do
        @repo_spy = nil
        Assert.stub(GGem::GitRepo, :new){ |*args| @repo_spy = GitRepoSpy.new(*args) }
      end
    end
  end

  class GenerateCommandTests < IOCommandTests
    include GitRepoSpyTests

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

      @command_class = GenerateCommand
      @cmd = @command_class.new
    end

    should "be a valid command" do
      assert_kind_of ValidCommand, subject
    end

    should "know its summary" do
      exp = "Create a gem given a GEM-NAME"
      assert_equal exp, subject.summary
    end

    should "know its help" do
      exp = "Usage: ggem generate [options] GEM-NAME\n\n" \
            "Options: #{subject.clirb}\n" \
            "Description:\n" \
            "  #{subject.summary}"
      assert_equal exp, subject.help
    end

    should "save a gem and initialize a git repo for it when run" do
      subject.run([@name], @stdout, @stderr)

      assert_equal [@path, @name], @gem_new_called_with
      assert_true @gem_spy.save_called

      assert_equal @gem_spy.path, @repo_spy.path
      assert_true @repo_spy.run_init_cmd_called

      exp = "created gem in #{@gem_spy.path}\n" \
            "initialized gem git repo\n"
      assert_equal exp, @stdout.read
    end

    should "re-raise a specific argument error on gem 'no name' errors" do
      Assert.stub(@gem_class, :new){ raise GGem::Gem::NoNameError }
      err = nil
      begin
        cmd = @command_class.new
        cmd.run([])
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
      @gem1_root_path = TEST_SUPPORT_PATH.join("gem1")
      Assert.stub(Dir, :pwd){ @gem1_root_path}

      @command_class = Class.new{ include GemspecCommand }
      @cmd = @command_class.new
    end

    should "be a valid, notify cmd command" do
      assert_kind_of ValidCommand,     subject
      assert_kind_of NotifyCmdCommand, subject
    end

    should "build a new gemspec at the current pwd root" do
      gemspec_new_called_with = nil
      Assert.stub(GGem::Gemspec, :new){ |*args| gemspec_new_called_with = args }

      @command_class.new
      assert_equal [Dir.pwd], gemspec_new_called_with
    end

    should "complain if no gemspec file can be found at the current pwd" do
      root = Factory.path
      Assert.stub(Dir, :pwd){ root }

      begin
        cmd = @command_class.new
      rescue ArgumentError => err
      end
      assert_not_nil err
      exp = "There are no gemspecs at #{Dir.pwd}"
      assert_equal exp, err.message
    end
  end

  module GemspecSpyTests
    include MuchPlugin

    plugin_included do
      include RootPathTests

      setup do
        @spec_spy = nil
        Assert.stub(GGem::Gemspec, :new){ |*args| @spec_spy = GemspecSpy.new(*args) }
      end
    end
  end

  class BuildCommandTests < IOCommandTests
    include GemspecSpyTests

    desc "BuildCommand"
    setup do
      @command_class = BuildCommand
      @cmd = @command_class.new
    end

    should "be a gemspec command" do
      assert_kind_of GemspecCommand, subject
    end

    should "know its summary" do
      exp = "Build #{@spec_spy.gem_file_name} into the " \
            "#{GGem::Gemspec::BUILD_TO_DIRNAME} directory"
      assert_equal exp, subject.summary
    end

    should "know its help" do
      exp = "Usage: ggem build [options]\n\n" \
            "Options: #{subject.clirb}\n" \
            "Description:\n" \
            "  #{subject.summary}"
      assert_equal exp, subject.help
    end

    should "call the spec's run build cmd when run" do
      ENV["DEBUG"] = [nil, "1"].sample
      subject.run([], @stdout, @stderr)

      assert_true @spec_spy.run_build_cmd_called

      exp = ENV["DEBUG"] == "1" ? "build\nbuild cmd was run\n" : ""
      exp += "#{@spec_spy.name} #{@spec_spy.version} built to #{@spec_spy.gem_file}\n"
      assert_equal exp, @stdout.read

      ENV["DEBUG"] = nil
    end

    should "handle cmd errors when run" do
      err_msg = Factory.string
      Assert.stub(@spec_spy, :run_build_cmd){ raise GGem::Gemspec::CmdError, err_msg }

      assert_raises(CommandExitError){ subject.run([], @stdout, @stderr) }
      assert_equal "#{err_msg}\n", @stderr.read
    end
  end

  class InstallCommandTests < IOCommandTests
    include GemspecSpyTests

    desc "InstallCommand"
    setup do
      @build_spy = nil
      Assert.stub(BuildCommand, :new){ |*args| @build_spy = CommandSpy.new(*args) }

      @command_class = InstallCommand
      @cmd = @command_class.new
    end

    should "be a gemspec command" do
      assert_kind_of GemspecCommand, subject
    end

    should "know its summary" do
      exp = "Build and install #{@spec_spy.gem_file_name} into system gems"
      assert_equal exp, subject.summary
    end

    should "know its help" do
      exp = "Usage: ggem install [options]\n\n" \
            "Options: #{subject.clirb}\n" \
            "Description:\n" \
            "  #{subject.summary}"
      assert_equal exp, subject.help
    end

    should "build a build command" do
      assert @build_spy
    end

    should "run the build command and call the spec's run install cmds when run" do
      ENV["DEBUG"] = [nil, "1"].sample
      subject.run(@argv, @stdout, @stderr)

      assert_true @build_spy.run_called
      assert_equal [], @build_spy.argv
      assert_true @spec_spy.run_install_cmd_called

      exp = ENV["DEBUG"] == "1" ? "install\ninstall cmd was run\n" : ""
      exp += "#{@spec_spy.name} #{@spec_spy.version} installed to system gems\n"
      assert_includes exp, @stdout.read

      ENV["DEBUG"] = nil
    end

    should "handle cmd errors when run" do
      err_msg = Factory.string
      Assert.stub(@spec_spy, :run_install_cmd){ raise GGem::Gemspec::CmdError, err_msg }

      assert_raises(CommandExitError){ subject.run(@argv, @stdout, @stderr) }
      assert_equal "#{err_msg}\n", @stderr.read
    end
  end

  class PushCommandTests < IOCommandTests
    include GemspecSpyTests

    desc "PushCommand"
    setup do
      @build_spy = nil
      Assert.stub(BuildCommand, :new){ |*args| @build_spy = CommandSpy.new(*args) }

      @command_class = PushCommand
      @cmd = @command_class.new
    end

    should "be a gemspec command" do
      assert_kind_of GemspecCommand, subject
    end

    should "know its summary" do
      exp = "Push built #{@spec_spy.gem_file_name} to #{@spec_spy.push_host}"
      assert_equal exp, subject.summary
    end

    should "know its help" do
      exp = "Usage: ggem push [options]\n\n" \
            "Options: #{subject.clirb}\n" \
            "Description:\n" \
            "  #{subject.summary}"
      assert_equal exp, subject.help
    end

    should "build a build command" do
      assert @build_spy
    end

    should "run the build command and call the spec's run push cmds when run" do
      ENV["DEBUG"] = [nil, "1"].sample
      subject.run(@argv, @stdout, @stderr)

      assert_true @build_spy.run_called
      assert_equal [], @build_spy.argv
      assert_true @spec_spy.run_push_cmd_called

      exp = "Pushing #{@spec_spy.gem_file_name} to #{@spec_spy.push_host}...\n"
      exp += ENV["DEBUG"] == "1" ? "push\npush cmd was run\n" : ""
      exp += "#{@spec_spy.gem_file_name} received.\n"
      assert_equal exp, @stdout.read

      ENV["DEBUG"] = nil
    end

    should "handle cmd errors when run" do
      err_msg = Factory.string
      Assert.stub(@spec_spy, :run_push_cmd){ raise GGem::Gemspec::CmdError, err_msg }

      assert_raises(CommandExitError){ subject.run(@argv, @stdout, @stderr) }
      assert_equal "#{err_msg}\n", @stderr.read
    end
  end

  class ForceTagOptionCommandTests < IOCommandTests
    desc "ForceTagOptionCommand"
    setup do
      @command_class = Class.new{ include ForceTagOptionCommand }
      @cmd = @command_class.new
    end

    should "be a valid command" do
      assert_kind_of ValidCommand, subject
    end

    should "add a force-tag CLIRB option" do
      subject.run(["-f"], @stdout, @stderr)
      assert_true subject.clirb.opts["force-tag"]
    end
  end

  class TagCommandTests < IOCommandTests
    include GitRepoSpyTests
    include GemspecSpyTests

    desc "TagCommand"
    setup do
      @command_class = TagCommand
      @cmd = @command_class.new
    end

    should "be a git repo, gemspec, force tag option command" do
      assert_kind_of GitRepoCommand,        subject
      assert_kind_of GemspecCommand,        subject
      assert_kind_of ForceTagOptionCommand, subject
    end

    should "know its summary" do
      exp = "Tag #{@spec_spy.version_tag} and push git commits/tags"
      assert_equal exp, subject.summary
    end

    should "know its help" do
      exp = "Usage: ggem tag [options]\n\n" \
            "Options: #{subject.clirb}\n" \
            "Description:\n" \
            "  #{subject.summary}"
      assert_equal exp, subject.help
    end

    should "call the repo's run build/push cmds when run" do
      ENV["DEBUG"] = [nil, "1"].sample
      subject.run([], @stdout, @stderr)

      assert_true @repo_spy.run_validate_clean_cmd_called
      assert_true @repo_spy.run_validate_committed_cmd_called

      exp = [@spec_spy.version, @spec_spy.version_tag]
      assert_equal exp, @repo_spy.run_add_version_tag_cmd_called_with

      assert_true @repo_spy.run_push_cmd_called
      assert_nil @repo_spy.run_rm_tag_cmd_called_with

      exp = if ENV["DEBUG"] == "1"
        "validate clean\nvalidate clean cmd was run\n" \
        "validate committed\nvalidate committed cmd was run\n" \
        "add tag\nadd tag cmd was run\n"
      else
        ""
      end
      exp += "Tagged #{@spec_spy.version_tag}.\n"
      exp += ENV["DEBUG"] == "1" ? "push\npush cmd was run\n" : ""
      exp += "Pushed git commits and tags.\n"
      assert_equal exp, @stdout.read

      ENV["DEBUG"] = nil
    end

    should "handle validation cmd errors when run" do
      err_msg = Factory.string
      err_on = [:run_validate_clean_cmd, :run_validate_committed_cmd].sample
      Assert.stub(@repo_spy, err_on){ raise GGem::GitRepo::CmdError, err_msg }

      assert_raises(CommandExitError){ subject.run([], @stdout, @stderr) }
      exp = "There are files that need to be committed first.\n"
      assert_equal exp, @stderr.read
    end

    should "ignore validation cmd errors when run with the force-tag option" do
      err_msg = Factory.string
      err_on = [:run_validate_clean_cmd, :run_validate_committed_cmd].sample
      Assert.stub(@repo_spy, err_on){ raise GGem::GitRepo::CmdError, err_msg }

      subject.run([["--force-tag", "-f"].sample], @stdout, @stderr)
      exp = "There are files that need to be committed first.\n" \
            "Forcing tag anyway...\n"
      assert_equal exp, @stderr.read
    end

    should "handle non-validation cmd errors when run" do
      err_msg = Factory.string
      err_on = [:run_add_version_tag_cmd, :run_push_cmd].sample
      Assert.stub(@repo_spy, err_on){ raise GGem::GitRepo::CmdError, err_msg }

      assert_raises(CommandExitError){ subject.run([], @stdout, @stderr) }
      assert_equal "#{err_msg}\n", @stderr.read
    end

    should "remove the version tag on push errors" do
      err_msg = Factory.string
      Assert.stub(@repo_spy, :run_push_cmd){ raise GGem::GitRepo::CmdError, err_msg }

      assert_raises(CommandExitError){ subject.run([], @stdout, @stderr) }
      assert_equal "#{err_msg}\n", @stderr.read

      exp = [@spec_spy.version_tag]
      assert_equal exp, @repo_spy.run_rm_tag_cmd_called_with
    end

    should "handle tag removal cmd errors when run" do
      Assert.stub(@repo_spy, :run_push_cmd){ raise GGem::GitRepo::CmdError, Factory.string }
      err_msg = Factory.string
      Assert.stub(@repo_spy, :run_rm_tag_cmd){ raise GGem::GitRepo::CmdError, err_msg }

      assert_raises(CommandExitError){ subject.run([], @stdout, @stderr) }
      assert_equal "#{err_msg}\n", @stderr.read
    end
  end

  class ReleaseCommandTests < IOCommandTests
    include GemspecSpyTests

    desc "ReleaseCommand"
    setup do
      @tag_spy = nil
      Assert.stub(TagCommand, :new){ |*args| @tag_spy = CommandSpy.new(*args) }

      @push_spy = nil
      Assert.stub(PushCommand, :new){ |*args| @push_spy = CommandSpy.new(*args) }

      @command_class = ReleaseCommand
      @cmd = @command_class.new
    end

    should "be a gemspec, force tag option command" do
      assert_kind_of GemspecCommand,        subject
      assert_kind_of ForceTagOptionCommand, subject
    end

    should "know its summary" do
      exp = "Tag #{@spec_spy.version_tag} and push built #{@spec_spy.gem_file_name} to " \
               "#{@spec_spy.push_host}"
      assert_equal exp, subject.summary
    end

    should "know its help" do
      exp = "Usage: ggem release [options]\n\n" \
            "Options: #{subject.clirb}\n" \
            "Description:\n" \
            "  #{subject.summary}\n" \
            "  (macro for running `ggem tag && ggem push`)"
      assert_equal exp, subject.help
    end

    should "build a tag and push command" do
      [@tag_spy, @push_spy].each do |spy|
        assert spy
      end
    end

    should "run the tag and push command when run" do
      subject.run(@argv, @stdout, @stderr)

      assert_true @tag_spy.run_called
      assert_equal [], @tag_spy.argv

      assert_true @push_spy.run_called
      assert_equal [], @push_spy.argv
    end

    should "pass any force-tag option to the tag cmd but not the release cmd" do
      force_tag_argv = [["--force-tag", "-f"].sample]
      subject.run(force_tag_argv, @stdout, @stderr)

      assert_true @tag_spy.run_called
      assert_equal ["--force-tag"], @tag_spy.argv

      assert_true @push_spy.run_called
      assert_equal [], @push_spy.argv
    end
  end

  class CommandSetTests < UnitTests
    desc "CommandSet"
    setup do
      @unknown_cmd_block_called_with = nil
      @set = CommandSet.new{ |*args| @unknown_cmd_block_called_with = args }
    end
    subject{ @set }

    should have_imeths :add, :remove, :[], :size

    should "add/rm commands, be able to look them up and know its size" do
      assert_equal 0,  subject.size
      assert_equal "", subject.to_s

      subject.add(CommandSpy, "test", "t", "tst")
      assert_equal 1, subject.size

      assert_instance_of CommandSpy, subject["test"]
      assert_same subject["test"], subject["t"]
      assert_same subject["test"], subject["tst"]

      exp_strs = ["test (t, tst) # #{subject["test"].summary}"]
      assert_equal exp_strs.join("\n"), subject.to_s

      subject.add(CommandSpy, "add1")
      exp_strs << "add1          # #{subject["add1"].summary}"

      @cmd_spy = CommandSpy.new
      Assert.stub(@cmd_spy, :summary){ [nil, ""].sample }
      Assert.stub(CommandSpy, :new){ @cmd_spy }

      subject.add(CommandSpy, "add2", "add")
      exp_strs << "add2 (add)    "

      subject.add(CommandSpy, "add3")
      Assert.stub(subject["add3"], :summary){ [nil, ""].sample }
      exp_strs << "add3          "

      assert_equal exp_strs.join("\n"), subject.to_s

      subject.remove("test")
      subject.remove("add1")
      subject.remove("add2")
      subject.remove("add3")

      assert_equal 0,  subject.size
      assert_equal "", subject.to_s
    end

    should "call the given block when looking up unknown command names" do
      unknown_cmd_name = Factory.string
      subject[unknown_cmd_name]
      assert_equal [unknown_cmd_name], @unknown_cmd_block_called_with
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
    attr_reader :argv, :stdout, :stderr, :run_called

    def initialize
      @argv = nil
      @stdout, @stderr = nil, nil
      @run_called = false
    end

    def run(argv, stdout = nil, stderr = nil)
      @argv = argv
      @stdout, @stderr = stdout, stderr
      @run_called = true
    end

    def summary
      @summary ||= Factory.string
    end

    def help
      @help ||= Factory.text
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
    attr_reader :name, :version, :version_tag, :push_host
    attr_reader :run_build_cmd_called, :run_install_cmd_called, :run_push_cmd_called

    def initialize(root_path)
      @root        = Pathname.new(File.expand_path(root_path))
      @name        = Factory.string
      @version     = Factory.string
      @version_tag = Factory.string
      @push_host   = Factory.url

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
      ["build", 0, "build cmd was run"]
    end

    def run_install_cmd
      @run_install_cmd_called = true
      ["install", 0, "install cmd was run"]
    end

    def run_push_cmd
      @run_push_cmd_called = true
      ["push", 0, "push cmd was run"]
    end
  end

  class GitRepoSpy
    attr_reader :path
    attr_reader :run_init_cmd_called
    attr_reader :run_validate_clean_cmd_called, :run_validate_committed_cmd_called
    attr_reader :run_add_version_tag_cmd_called_with, :run_rm_tag_cmd_called_with
    attr_reader :run_push_cmd_called

    def initialize(path)
      @path = path

      @run_init_cmd_called = false

      @run_validate_clean_cmd_called     = false
      @run_validate_committed_cmd_called = false

      @run_add_version_tag_cmd_called_with = nil
      @run_rm_tag_cmd_called_with          = nil

      @run_push_cmd_called = false
    end

    def run_init_cmd
      @run_init_cmd_called = true
      ["init", 0, "init cmd was run"]
    end

    def run_validate_clean_cmd
      @run_validate_clean_cmd_called = true
      ["validate clean", 0, "validate clean cmd was run"]
    end

    def run_validate_committed_cmd
      @run_validate_committed_cmd_called = true
      ["validate committed", 0, "validate committed cmd was run"]
    end

    def run_add_version_tag_cmd(*args)
      @run_add_version_tag_cmd_called_with = args
      ["add tag", 0, "add tag cmd was run"]
    end

    def run_rm_tag_cmd(*args)
      @run_rm_tag_cmd_called_with = args
      ["rm tag", 0, "rm tag cmd was run"]
    end

    def run_push_cmd
      @run_push_cmd_called = true
      ["push", 0, "push cmd was run"]
    end
  end
end
