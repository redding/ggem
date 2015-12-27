require 'pathname'
require 'scmd'

module GGem

  class Gemspec

    PUSH_HOST_META_KEY = 'allowed_push_host'
    DEFAULT_PUSH_HOST  = 'https://rubygems.org'.freeze
    BUILD_TO_DIRNAME   = 'pkg'.freeze

    attr_reader :path, :name, :version
    attr_reader :gem_file_name, :gem_file, :push_host

    def initialize(root_path)
      @root = Pathname.new(File.expand_path(root_path))
      raise NotFoundError unless @root.exist?
      @path = Pathname.new(Dir[File.join(@root, "{,*}.gemspec")].first.to_s)
      raise NotFoundError unless @path.exist?

      @spec    = load_gemspec(@path)
      @name    = @spec.name
      @version = @spec.version

      @gem_file_name  = "#{@name}-#{@version}.gem"
      @gem_file       = File.join(BUILD_TO_DIRNAME, @gem_file_name)
      @built_gem_path = @root.join(@gem_file)

      @push_host = get_push_host(@spec)
    end

    def run_build_cmd
      run_cmd("gem build --verbose #{@path}").tap do
        gem_path = @root.join(@gem_file_name)
        run_cmd("mkdir -p #{@built_gem_path.dirname}")
        run_cmd("mv #{gem_path} #{@built_gem_path}")
      end
    end

    def run_install_cmd
      run_cmd("gem install #{@built_gem_path}")
    end

    def run_push_cmd
      run_cmd("gem push #{@built_gem_path} --host #{@push_host}")
    end

    private

    def run_cmd(cmd_string)
      cmd = Scmd.new(cmd_string)
      cmd.run
      if !cmd.success?
        raise CmdError, "#{cmd_string}\n" \
                        "#{cmd.stderr.empty? ? cmd.stdout : cmd.stderr}"
      end
      [cmd_string, cmd.exitstatus, cmd.stdout]
    end

    def load_gemspec(path)
      eval(path.read, TOPLEVEL_BINDING, path.expand_path.to_s)
    rescue ScriptError, StandardError => e
      original_line = e.backtrace.find{ |line| line.include?(path.to_s) }
      msg = "There was a #{e.class} while loading #{path.basename}: \n#{e.message}"
      msg << " from\n  #{original_line}" if original_line
      msg << "\n"
      raise LoadError, msg
    end

    def get_push_host(spec)
      ENV['GGEM_PUSH_HOST'] || get_meta(spec)[PUSH_HOST_META_KEY] || DEFAULT_PUSH_HOST
    end

    def get_meta(spec)
      (spec.respond_to?(:metadata) ? spec.metadata : {}) || {}
    end

    NotFoundError = Class.new(ArgumentError)
    LoadError     = Class.new(ArgumentError)
    CmdError      = Class.new(RuntimeError)

  end

end
