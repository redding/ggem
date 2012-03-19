require 'erb'
require 'fileutils'

module GGem
  class Template

    def initialize(ggem)
      @gem = ggem
    end

    def save
      save_folder   # (gems root path)
      save_folder "lib/#{@gem.ruby_name}"
      save_folder "test"

      save_file('gitignore.erb', '.gitignore')
      save_file('Gemfile.erb',   'Gemfile')
      save_file('gemspec.erb',   "#{@gem.name}.gemspec")
      save_file('Rakefile.erb',  'Rakefile')
      save_file('README.md.erb', 'README.md')
      save_file('LICENSE.erb',   'LICENSE')

      save_file('lib.rb.erb',         "lib/#{@gem.ruby_name}.rb")
      save_file('lib_version.rb.erb', "lib/#{@gem.ruby_name}/version.rb")

      save_file('test_irb.rb.erb',    'test/irb.rb')
      save_file('test_helper.rb.erb', 'test/helper.rb')
      save_file('test.rb.erb',        "test/#{@gem.ruby_name}_test.rb")
    end

    def init
      `cd #{@gem.path} && git init && git add --all`
    end

    private

    def save_folder(relative_path=nil)
      FileUtils.mkdir_p(File.join([
        @gem.path, relative_path
      ].compact))
    end

    def save_file(source, output)
      source_file = File.join(File.dirname(__FILE__), 'template_file', source)
      output_file = File.join(@gem.root_path, @gem.name, output)

      if File.exists?(source_file)
        erb = ERB.new(File.read(source_file))
        File.open(output_file, 'w') {|f| f << erb.result(binding) }
      else
        raise ArgumentError, "the source file '#{source_file}' does not exist"
      end
    end

  end
end
