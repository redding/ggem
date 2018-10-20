require "assert"
require "ggem/gemspec"

require "ggem/version"
require "test/support/cmd_tests_helpers"

class GGem::Gemspec

  class UnitTests < Assert::Context
    desc "GGem::Gemspec"
    setup do
      @gemspec_class = GGem::Gemspec
    end
    subject{ @gemspec_class }

    should "know the push host meta key" do
      assert_equal "allowed_push_host", subject::PUSH_HOST_META_KEY
    end

    should "use Rubygems as its default push host" do
      assert_equal "https://rubygems.org", subject::DEFAULT_PUSH_HOST
    end

    should "know which dir to build gems to" do
      assert_equal "pkg", subject::BUILD_TO_DIRNAME
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
      @gem1_root_path = TEST_SUPPORT_PATH.join("gem1")
      @spec = @gemspec_class.new(@gem1_root_path)
    end
    subject{ @spec }

    should have_readers :path, :name, :version, :version_tag
    should have_readers :gem_file_name, :gem_file, :push_host
    should have_imeths :run_build_cmd, :run_install_cmd, :run_push_cmd

    should "know its attrs" do
      exp = @gem1_root_path.join("gem1.gemspec")
      assert_equal exp, subject.path

      assert_equal "gem1",   subject.name
      assert_equal "0.1.0",  subject.version.to_s
      assert_equal "v0.1.0", subject.version_tag

      exp = "#{subject.name}-#{subject.version}.gem"
      assert_equal exp, subject.gem_file_name

      exp = File.join(@gemspec_class::BUILD_TO_DIRNAME, subject.gem_file_name)
      assert_equal exp, subject.gem_file
    end

    should "know its push host" do
      # gem1 has no meta host specified, so the default push host is used
      assert_equal @gemspec_class::DEFAULT_PUSH_HOST, subject.push_host

      # gem2 has a meta host specified, so that is used over the default
      gem2_spec = @gemspec_class.new(TEST_SUPPORT_PATH.join("gem2"))
      assert_equal "http://gems.example.com", gem2_spec.push_host

      # prefer the env push hosts over configured and default hosts
      prev_env_push_host = ENV["GGEM_PUSH_HOST"]
      ENV["GGEM_PUSH_HOST"] = Factory.string
      spec = @gemspec_class.new(TEST_SUPPORT_PATH.join(["gem1", "gem2"].sample))
      assert_equal ENV["GGEM_PUSH_HOST"], spec.push_host
      ENV["GGEM_PUSH_HOST"] = prev_env_push_host
    end

    should "complain if the given gemspec root doesn't exist" do
      assert_raises(NotFoundError) do
        @gemspec_class.new("path/that-is/not-found")
      end
    end

    should "complain if the given gemspec root contains no gemspec file" do
      assert_raises(NotFoundError) do
        @gemspec_class.new(TEST_SUPPORT_PATH)
      end
    end

  end

  class CmdTests < InitTests
    include GGem::CmdTestsHelpers
    setup do
      @exp_build_path = @gem1_root_path.join(subject.gem_file_name)
      @exp_pkg_path   = @gem1_root_path.join(@gemspec_class::BUILD_TO_DIRNAME, subject.gem_file_name)
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
      assert_exp_cmds_run{ subject.run_build_cmd }
    end

    should "complain if any system cmds are not successful" do
      assert_exp_cmds_error(CmdError){ subject.run_build_cmd }
    end

  end

  class RunInstallCmdTests < CmdTests
    desc "`run_install_cmd`"
    setup do
      @exp_cmds_run = ["gem install #{@exp_pkg_path}"]
    end

    should "run a system cmd to install the gem" do
      assert_exp_cmds_run{ subject.run_install_cmd }
    end

    should "complain if the system cmd is not successful" do
      assert_exp_cmds_error(CmdError){ subject.run_install_cmd }
    end

  end

  class RunPushCmdTests < CmdTests
    desc "`run_push_cmd`"
    setup do
      @exp_cmds_run = ["gem push #{@exp_pkg_path} --host #{subject.push_host}"]
    end

    should "run a system cmd to push the gem to the push host" do
      assert_exp_cmds_run{ subject.run_push_cmd }
    end

    should "complain if the system cmd is not successful" do
      assert_exp_cmds_error(CmdError){ subject.run_push_cmd }
    end

  end

end
