require 'much-plugin'
require 'scmd'

module GGem

  module CmdTestsHelpers
    include MuchPlugin

    plugin_included do
      setup do
        ENV['SCMD_TEST_MODE'] = '1'

        @cmd_spy = nil
        Scmd.reset

        @exp_cmds_run = []
      end
      teardown do
        Scmd.reset
        ENV.delete('SCMD_TEST_MODE')
      end

      private

      def assert_exp_cmds_run(&run_cmd_block)
        cmd_str, exitstatus, stdout = run_cmd_block.call
        assert_equal @exp_cmds_run, Scmd.calls.map(&:cmd_str)

        assert_equal Scmd.calls.first.cmd_str,        cmd_str
        assert_equal Scmd.calls.first.cmd.exitstatus, exitstatus
        assert_equal Scmd.calls.first.cmd.stdout,     stdout
      end

      def assert_exp_cmds_error(cmd_error_class, &run_cmd_block)
        err_cmd_str = @exp_cmds_run.sample
        Scmd.add_command(err_cmd_str) do |cmd|
          cmd.exitstatus = 1
          cmd.stderr     = Factory.string
          @cmd_spy       = cmd
        end
        err = nil
        begin; run_cmd_block.call; rescue StandardError => err; end

        assert_kind_of cmd_error_class, err
        exp = "#{@cmd_spy.cmd_str}\n#{@cmd_spy.stderr}"
        assert_equal exp, err.message
      end

    end

  end

end
