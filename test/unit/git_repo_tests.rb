require "assert"
require "ggem/git_repo"

require 'scmd'

class GGem::GitRepo

  class UnitTests < Assert::Context
    desc "GGem::GitRepo"
    setup do
      @git_repo_class = GGem::GitRepo
    end
    subject{ @git_repo_class }

    should "know its exceptions" do
      assert subject::NotFoundError < ArgumentError
      assert subject::CmdError < RuntimeError
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @repo_path = TEST_SUPPORT_PATH.join('gem1')
      @repo = @git_repo_class.new(@repo_path)
    end
    subject{ @repo }

    should have_readers :path
    should have_imeths :run_init_cmd

    should "know its path" do
      assert_equal @repo_path, subject.path
    end

  end

  class CmdTests < InitTests
    setup do
      ENV['SCMD_TEST_MODE'] = '1'

      @cmd_spy = nil
      Scmd.reset
    end
    teardown do
      Scmd.reset
      ENV.delete('SCMD_TEST_MODE')
    end

  end

  class RunInitCmdTests < CmdTests
    desc "`run_init_cmd`"
    setup do
      @exp_cmds_run = [
        "cd #{@repo_path} && git init",
        "cd #{@repo_path} && git add --all && git add -f *.gitkeep"
      ]
    end

    should "run a system cmd to init the repo and add any existing files" do
      cmd_str, exitstatus, stdout = subject.run_init_cmd
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
        subject.run_init_cmd
      rescue StandardError => err
      end

      assert_kind_of CmdError, err
      exp = "#{@cmd_spy.cmd_str}\n#{@cmd_spy.stderr}"
      assert_equal exp, err.message
    end

  end

end
