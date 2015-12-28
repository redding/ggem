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

    def run_validate_clean_cmd
      run_cmd("git diff --exit-code")
    end

    def run_validate_committed_cmd
      run_cmd("git diff-index --quiet --cached HEAD")
    end

    def run_push_cmd
      run_cmd("git push").tap do
        run_cmd("git push --tags")
      end
    end

    def run_add_version_tag_cmd(version, tag)
      run_cmd("git tag -a -m \"Version #{version}\" #{tag}")
    end

    def run_rm_tag_cmd(tag)
      run_cmd("git tag -d #{tag}")
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
