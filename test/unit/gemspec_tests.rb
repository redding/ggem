require "assert"
require "ggem/gemspec"

require 'scmd'
require 'ggem/version'

class GGem::Gemspec

  class UnitTests < Assert::Context
    desc "GGem::Gemspec"
    setup do
      @gemspec_class = GGem::Gemspec
    end
    subject{ @gemspec_class }

    should "know the push host meta key" do
      assert_equal 'allowed_push_host', subject::PUSH_HOST_META_KEY
    end

    should "use Rubygems as its default push host" do
      assert_equal 'https://rubygems.org', subject::DEFAULT_PUSH_HOST
    end

    should "know which dir to build gems to" do
      assert_equal 'pkg', subject::BUILD_TO_DIRNAME
    end

    should "know its exceptions" do
      assert subject::NotFoundError < ArgumentError
      assert subject::LoadError < ArgumentError
      assert subject::CmdError < RuntimeError
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @gem1_root_path = TEST_SUPPORT_PATH.join('gem1')
      @spec = @gemspec_class.new(@gem1_root_path)
    end
    subject{ @spec }

    should have_readers :path, :name, :version
    should have_readers :gem_file_name, :gem_file, :push_host
    should have_imeths :run_build_cmd, :run_install_cmd, :run_push_cmd

    should "know its attrs" do
      exp = @gem1_root_path.join('gem1.gemspec')
      assert_equal exp, subject.path

      assert_equal 'gem1',  subject.name
      assert_equal '0.1.0', subject.version.to_s

      exp = "#{subject.name}-#{subject.version}.gem"
      assert_equal exp, subject.gem_file_name

      exp = File.join(@gemspec_class::BUILD_TO_DIRNAME, subject.gem_file_name)
      assert_equal exp, subject.gem_file
    end

    should "know its push host" do
      # gem1 has no meta host specified, so the default push host is used
      assert_equal @gemspec_class::DEFAULT_PUSH_HOST, subject.push_host

      # gem2 has a meta host specified, so that is used over the default
      gem2_spec = @gemspec_class.new(TEST_SUPPORT_PATH.join('gem2'))
      assert_equal 'http://gems.example.com', gem2_spec.push_host

      # prefer the env push hosts over configured and default hosts
      prev_env_push_host = ENV['GGEM_PUSH_HOST']
      ENV['GGEM_PUSH_HOST'] = Factory.string
      spec = @gemspec_class.new(TEST_SUPPORT_PATH.join(['gem1', 'gem2'].choice))
      assert_equal ENV['GGEM_PUSH_HOST'], spec.push_host
      ENV['GGEM_PUSH_HOST'] = prev_env_push_host
    end

    should "complain if the given gemspec root doesn't exist" do
      assert_raises(NotFoundError) do
        @gemspec_class.new('path/that-is/not-found')
      end
    end

    should "complain if the given gemspec root contains no gemspec file" do
      assert_raises(NotFoundError) do
        @gemspec_class.new(TEST_SUPPORT_PATH)
      end
    end

  end

  class CmdTests < InitTests
    setup do
      ENV['SCMD_TEST_MODE'] = '1'

      @exp_build_path = @gem1_root_path.join(subject.gem_file_name)
      @exp_pkg_path   = @gem1_root_path.join(@gemspec_class::BUILD_TO_DIRNAME, subject.gem_file_name)

      @cmd_spy = nil
      Scmd.reset
    end
    teardown do
      Scmd.reset
      ENV.delete('SCMD_TEST_MODE')
    end

  end

  class RunBuildCmdTests < CmdTests
    desc "`run_build_cmd`"
    setup do
      @exp_cmds_run = [
        "gem build --verbose #{subject.path}",
        "mkdir -p #{@exp_pkg_path.dirname}",
        "mv #{@exp_build_path} #{@exp_pkg_path}"
      ]
    end

    should "run system cmds to build the gem" do
      cmd_str, exitstatus, stdout = subject.run_build_cmd
      assert_equal @exp_cmds_run, Scmd.calls.map(&:cmd_str)

      assert_equal Scmd.calls.first.cmd_str,        cmd_str
      assert_equal Scmd.calls.first.cmd.exitstatus, exitstatus
      assert_equal Scmd.calls.first.cmd.stdout,     stdout
    end

    should "complain if any system cmds are not successful" do
      err_cmd_str = @exp_cmds_run.choice
      Scmd.add_command(err_cmd_str) do |cmd|
        cmd.exitstatus = 1
        cmd.stderr     = Factory.string
        @cmd_spy       = cmd
      end
      err = nil
      begin
        subject.run_build_cmd
      rescue StandardError => err
      end

      assert_kind_of CmdError, err
      exp = "#{@cmd_spy.cmd_str}\n#{@cmd_spy.stderr}"
      assert_equal exp, err.message
    end

  end

  class RunInstallCmdTests < CmdTests
    desc "`run_install_cmd`"
    setup do
      @exp_cmds_run = ["gem install #{@exp_pkg_path}"]
    end

    should "run a system cmd to install the gem" do
      cmd_str, exitstatus, stdout = subject.run_install_cmd
      assert_equal @exp_cmds_run, Scmd.calls.map(&:cmd_str)

      assert_equal Scmd.calls.last.cmd_str,        cmd_str
      assert_equal Scmd.calls.last.cmd.exitstatus, exitstatus
      assert_equal Scmd.calls.last.cmd.stdout,     stdout
    end

    should "complain if the system cmd is not successful" do
      err_cmd_str = @exp_cmds_run.choice
      Scmd.add_command(err_cmd_str) do |cmd|
        cmd.exitstatus = 1
        cmd.stderr     = Factory.string
        @cmd_spy       = cmd
      end
      err = nil
      begin
        subject.run_install_cmd
      rescue StandardError => err
      end

      assert_kind_of CmdError, err
      exp = "#{@cmd_spy.cmd_str}\n#{@cmd_spy.stderr}"
      assert_equal exp, err.message
    end

  end

  class RunPushCmdTests < CmdTests
    desc "`run_push_cmd`"
    setup do
      @exp_cmds_run = ["gem push #{@exp_pkg_path} --host #{subject.push_host}"]
    end

    should "run a system cmd to push the gem to the push host" do
      cmd_str, exitstatus, stdout = subject.run_push_cmd
      assert_equal @exp_cmds_run, Scmd.calls.map(&:cmd_str)

      assert_equal Scmd.calls.last.cmd_str,        cmd_str
      assert_equal Scmd.calls.last.cmd.exitstatus, exitstatus
      assert_equal Scmd.calls.last.cmd.stdout,     stdout
    end

    should "complain if the system cmd is not successful" do
      err_cmd_str = @exp_cmds_run.choice
      Scmd.add_command(err_cmd_str) do |cmd|
        cmd.exitstatus = 1
        cmd.stderr     = Factory.string
        @cmd_spy       = cmd
      end
      err = nil
      begin
        subject.run_push_cmd
      rescue StandardError => err
      end

      assert_kind_of CmdError, err
      exp = "#{@cmd_spy.cmd_str}\n#{@cmd_spy.stderr}"
      assert_equal exp, err.message
    end

  end

end
