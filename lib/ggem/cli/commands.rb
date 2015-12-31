require 'ggem/cli/clirb'
require 'much-plugin'

module GGem; end
class GGem::CLI

  InvalidCommandError = Class.new(ArgumentError)
  CommandExitError    = Class.new(RuntimeError)

  class InvalidCommand

    attr_reader :name, :clirb

    def initialize(name)
      @name  = name
      @clirb = CLIRB.new
    end

    def new(*args)
      self
    end

    def run(argv)
      @clirb.parse!([@name, argv].flatten.compact)
      raise CLIRB::HelpExit if @name.to_s.empty?
      raise InvalidCommandError, "'#{self.name}' is not a command."
    end

    def help
      "Usage: ggem [COMMAND] [options]\n\n" \
      "Commands: #{COMMANDS.keys.sort.join(', ')}\n" \
      "Options: #{@clirb}"
    end

  end

  module ValidCommand
    include MuchPlugin

    plugin_included do
      include InstanceMethods
    end

    module InstanceMethods

      def initialize(stdout = nil, stderr = nil)
        @stdout = stdout || $stdout
        @stderr = stderr || $stderr
        @clirb  = CLIRB.new
      end

      def clirb; @clirb; end

      def run(argv)
        @clirb.parse!(argv)
      end

    end

  end

  module NotifyCmdCommand
    include MuchPlugin

    plugin_included do
      include InstanceMethods
    end

    module InstanceMethods

      private

      def notify(success_msg, &cmd_block)
        cmd(&cmd_block)
        @stdout.puts success_msg
      end

      def cmd(&cmd_block)
        cmd, status, output = cmd_block.call
        if ENV['DEBUG']
          @stdout.puts cmd
          @stdout.puts output
        end
      end

    end

  end

  module GitRepoCommand
    include MuchPlugin

    plugin_included do
      include ValidCommand
      include NotifyCmdCommand
      include InstanceMethods
    end

    module InstanceMethods
      def initialize(*args)
        super

        require 'ggem/git_repo'
        @repo = GGem::GitRepo.new(Dir.pwd)
      end

      private

      def notify(*args, &block)
        begin
          super
        rescue GGem::GitRepo::CmdError => exception
          @stderr.puts exception.message
          raise CommandExitError
        end
      end

    end
  end

  class GenerateCommand
    include GitRepoCommand

    def run(argv)
      super

      begin
        require 'ggem/gem'
        path = GGem::Gem.new(Dir.pwd, @clirb.args.first).save!.path
        @stdout.puts "created gem in #{path}"
      rescue GGem::Gem::NoNameError => exception
        error = ArgumentError.new("GEM-NAME must be provided")
        error.set_backtrace(exception.backtrace)
        raise error
      end

      @repo = GGem::GitRepo.new(path)
      notify("initialized gem git repo"){ @repo.run_init_cmd }
    end

    def help
      "Usage: ggem generate [options] GEM-NAME\n\n" \
      "Options: #{@clirb}"
    end

  end

  module GemspecCommand
    include MuchPlugin

    plugin_included do
      include ValidCommand
      include NotifyCmdCommand
      include InstanceMethods
    end

    module InstanceMethods
      def initialize(*args)
        super

        require 'ggem/gemspec'
        begin
          @spec = GGem::Gemspec.new(Dir.pwd)
        rescue GGem::Gemspec::NotFoundError => exception
          @stderr.puts "There are no gemspecs at #{Dir.pwd}"
          raise CommandExitError
        end
      end

      private

      def notify(*args, &block)
        begin
          super
        rescue GGem::Gemspec::CmdError => exception
          @stderr.puts exception.message
          raise CommandExitError
        end
      end

    end
  end

  class BuildCommand
    include GemspecCommand

    def run(argv)
      super
      notify("#{@spec.name} #{@spec.version} built to #{@spec.gem_file}") do
        @spec.run_build_cmd
      end
    end

    def help
      "Usage: ggem build [options]\n\n" \
      "Options: #{@clirb}\n" \
      "Description:\n" \
      "  Build #{@spec.gem_file_name} into the " \
         "#{GGem::Gemspec::BUILD_TO_DIRNAME} directory"
    end

  end

  class InstallCommand
    include GemspecCommand

    def initialize(*args)
      super
      @build_command = BuildCommand.new(*args)
    end

    def run(argv)
      super
      @build_command.run(argv)
      notify("#{@spec.name} #{@spec.version} installed to system gems") do
        @spec.run_install_cmd
      end
    end

    def help
      "Usage: ggem install [options]\n\n" \
      "Options: #{@clirb}\n" \
      "Description:\n" \
      "  Build and install #{@spec.gem_file_name} into system gems"
    end

  end

  class PushCommand
    include GemspecCommand

    def initialize(*args)
      super
      @build_command = BuildCommand.new(*args)
    end

    def run(argv)
      super
      @build_command.run(argv)

      @stdout.puts "Pushing #{@spec.gem_file_name} to #{@spec.push_host}..."
      notify("#{@spec.gem_file_name} received.") do
        @spec.run_push_cmd
      end
    end

    def help
      "Usage: ggem push [options]\n\n" \
      "Options: #{@clirb}\n" \
      "Description:\n" \
      "  Push built #{@spec.gem_file_name} to #{@spec.push_host}"
    end

  end

  class TagCommand
    include GitRepoCommand
    include GemspecCommand

    def run(argv)
      super

      begin
        cmd{ @repo.run_validate_clean_cmd }
        cmd{ @repo.run_validate_committed_cmd }
      rescue GGem::GitRepo::CmdError => err
        @stderr.puts "There are files that need to be committed first."
        raise CommandExitError
      end

      cmd{ @repo.run_add_version_tag_cmd(@spec.version, @spec.version_tag) }

      @stdout.puts "Tagged #{@spec.version_tag}."

      begin
        cmd{ @repo.run_push_cmd }
      rescue
        cmd{ @repo.run_rm_tag_cmd(@spec.version_tag) }
        raise
      end

      @stdout.puts "Pushed git commits and tags."
    rescue GGem::GitRepo::CmdError => err
      @stderr.puts err.message
      raise CommandExitError
    end

    def help
      "Usage: ggem tag [options]\n\n" \
      "Options: #{@clirb}\n" \
      "Description:\n" \
      "  Tag #{@spec.version_tag} and push git commits/tags"
    end

  end

  class ReleaseCommand
    include GemspecCommand

    def initialize(*args)
      super
      @tag_command  = TagCommand.new(*args)
      @push_command = PushCommand.new(*args)
    end

    def run(argv)
      super
      @tag_command.run(argv)
      @push_command.run(argv)
    end

    def help
      "Usage: ggem release [options]\n\n" \
      "Options: #{@clirb}\n" \
      "Description:\n" \
      "  Tag #{@spec.version_tag} and push built #{@spec.gem_file_name} to " \
         "#{@spec.push_host}\n" \
      "  (macro for running `ggem tag && ggem push`)"
    end

  end

end
