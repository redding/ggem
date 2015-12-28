require 'ggem/version'
require 'ggem/clirb'
require 'much-plugin'

module GGem

  class CLI

    class InvalidCommand;  end
    class GenerateCommand; end
    class BuildCommand;    end
    class InstallCommand;  end
    class PushCommand;     end
    class TagCommand;      end
    class ReleaseCommand;  end
    COMMANDS = Hash.new{ |h, k| InvalidCommand.new(k) }.tap do |h|
      h['generate'] = GenerateCommand
      h['g']        = GenerateCommand
      h['build']    = BuildCommand
      h['install']  = InstallCommand
      h['push']     = PushCommand
      h['tag']      = TagCommand
      h['release']  = ReleaseCommand
    end

    def self.run(args)
      self.new.run(args)
    end

    def initialize(kernel = nil, stdout = nil, stderr = nil)
      @kernel = kernel || Kernel
      @stdout = stdout || $stdout
      @stderr = stderr || $stderr
    end

    def run(args)
      begin
        cmd_name = args.shift
        cmd = COMMANDS[cmd_name].new(args)
        cmd.run
      rescue CLIRB::HelpExit
        @stdout.puts cmd.help
      rescue CLIRB::VersionExit
        @stdout.puts GGem::VERSION
      rescue CLIRB::Error, ArgumentError, InvalidCommandError => exception
        display_debug(exception)
        @stderr.puts "#{exception.message}\n\n"
        @stdout.puts cmd.help
        @kernel.exit 1
      rescue CommandExitError
        @kernel.exit 1
      rescue StandardError => exception
        @stderr.puts "#{exception.class}: #{exception.message}"
        @stderr.puts exception.backtrace.join("\n")
        @kernel.exit 1
      end
      @kernel.exit 0
    end

    private

    def display_debug(exception)
      if ENV['DEBUG']
        @stderr.puts "#{exception.class}: #{exception.message}"
        @stderr.puts exception.backtrace.join("\n")
      end
    end

    InvalidCommandError = Class.new(ArgumentError)
    CommandExitError    = Class.new(RuntimeError)

    class InvalidCommand

      attr_reader :name, :argv, :clirb

      def initialize(name)
        @name  = name
        @argv  = []
        @clirb = GGem::CLIRB.new
      end

      def new(args)
        @argv = [@name, args].flatten.compact
        self
      end

      def run
        @clirb.parse!(@argv)
        raise CLIRB::HelpExit if @clirb.args.empty? || @name.to_s.empty?
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

        def initialize(argv, stdout = nil, stderr = nil)
          @argv   = argv
          @stdout = stdout || $stdout
          @stderr = stderr || $stderr

          @clirb = GGem::CLIRB.new
        end

        def clirb; @clirb; end

        def run
          @clirb.parse!(@argv)
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

      def run
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

      def run
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

      def run
        super
        @build_command.run
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

      def run
        super
        @build_command.run

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

      def run
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

      def run
        super
        @tag_command.run
        @push_command.run
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

end
