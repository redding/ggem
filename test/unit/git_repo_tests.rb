# frozen_string_literal: true

require "assert"
require "ggem/git_repo"

require "test/support/cmd_tests_helpers"

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
      @repo_path = TEST_SUPPORT_PATH.join("gem1")
      @repo = @git_repo_class.new(@repo_path)
    end
    subject{ @repo }

    should have_readers :path
    should have_imeths :run_init_cmd
    should have_imeths :run_validate_clean_cmd, :run_validate_committed_cmd
    should have_imeths :run_push_cmd
    should have_imeths :run_add_version_tag_cmd, :run_rm_tag_cmd

    should "know its path" do
      assert_equal @repo_path, subject.path
    end
  end

  class CmdTests < InitTests
    include GGem::CmdTestsHelpers
  end

  class RunInitCmdTests < CmdTests
    desc "`run_init_cmd`"
    setup do
      @exp_cmds_run = [
        "cd #{@repo_path} && git init",
        "cd #{@repo_path} && git add --all && git add -f *.keep"
      ]
    end

    should "run a system cmd to init the repo and add any existing files" do
      assert_exp_cmds_run{ subject.run_init_cmd }
    end

    should "complain if any system cmds are not successful" do
      assert_exp_cmds_error(CmdError){ subject.run_init_cmd }
    end
  end

  class RunValidateCleanCmdTests < CmdTests
    desc "`run_validate_clean_cmd`"
    setup do
      @exp_cmds_run = [
        "cd #{@repo_path} && git diff --exit-code"
      ]
    end

    should "run a system cmd to see if there are any diffs" do
      assert_exp_cmds_run{ subject.run_validate_clean_cmd }
    end

    should "complain if any system cmds are not successful" do
      assert_exp_cmds_error(CmdError){ subject.run_validate_clean_cmd }
    end
  end

  class RunValidateCommittedCmdTests < CmdTests
    desc "`run_validate_committed_cmd`"
    setup do
      @exp_cmds_run = [
        "cd #{@repo_path} && git diff-index --quiet --cached HEAD"
      ]
    end

    should "run a system cmd to see if there is anything still uncommitted" do
      assert_exp_cmds_run{ subject.run_validate_committed_cmd }
    end

    should "complain if any system cmds are not successful" do
      assert_exp_cmds_error(CmdError){ subject.run_validate_committed_cmd }
    end
  end

  class RunPushCmdTests < CmdTests
    desc "`run_push_cmd`"
    setup do
      @exp_cmds_run = [
        "cd #{@repo_path} && git push",
        "cd #{@repo_path} && git push --tags"
      ]
    end

    should "run a system cmds to push commits/tags" do
      assert_exp_cmds_run{ subject.run_push_cmd }
    end

    should "complain if any system cmds are not successful" do
      assert_exp_cmds_error(CmdError){ subject.run_push_cmd }
    end
  end

  class RunAddVersionTagCmdTests < CmdTests
    desc "`run_add_version_tag_cmd`"
    setup do
      @version = Factory.string
      @tag     = Factory.string

      @exp_cmds_run = [
        "cd #{@repo_path} && git tag -a -m \"Version #{@version}\" #{@tag}"
      ]
    end

    should "run a system cmd to add a tag for a given version/tag string" do
      assert_exp_cmds_run{ subject.run_add_version_tag_cmd(@version, @tag) }
    end

    should "complain if any system cmds are not successful" do
      assert_exp_cmds_error(CmdError){ subject.run_add_version_tag_cmd(@version, @tag) }
    end
  end

  class RunRmTagCmdTests < CmdTests
    desc "`run_rm_tag_cmd`"
    setup do
      @tag = Factory.string

      @exp_cmds_run = [
        "cd #{@repo_path} && git tag -d #{@tag}"
      ]
    end

    should "run a system cmd to remove a tag with the given tag string" do
      assert_exp_cmds_run{ subject.run_rm_tag_cmd(@tag) }
    end

    should "complain if any system cmds are not successful" do
      assert_exp_cmds_error(CmdError){ subject.run_rm_tag_cmd(@tag) }
    end
  end
end
