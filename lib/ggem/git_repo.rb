require 'pathname'
require 'scmd'

module GGem

  class GitRepo

    attr_reader :path

    def initialize(repo_path)
      @path = Pathname.new(File.expand_path(repo_path))
    end

    def run_init_cmd
      run_cmd("git init").tap do
        run_cmd("git add --all && git add -f *.gitkeep")
      end
    end

    private

    def run_cmd(cmd_string)
      cmd_string = "cd #{@path} && #{cmd_string}"
      cmd = Scmd.new(cmd_string)
      cmd.run
      if !cmd.success?
        raise CmdError, "#{cmd_string}\n" \
                        "#{cmd.stderr.empty? ? cmd.stdout : cmd.stderr}"
      end
      [cmd_string, cmd.exitstatus, cmd.stdout]
    end

    NotFoundError = Class.new(ArgumentError)
    CmdError      = Class.new(RuntimeError)

  end

end
