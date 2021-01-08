# frozen_string_literal: true

require "erb"
require "fileutils"

module GGem; end

class GGem::Template
  def initialize(ggem)
    @ggem = ggem
  end

  def save
    save_folder # (gem root path)
    save_folder "lib/#{@ggem.ruby_name}"
    save_folder "test/support"
    save_folder "test/system"
    save_folder "test/unit"
    save_folder "log"
    save_folder "tmp"

    save_file("ruby-version.erb", ".ruby-version")
    save_file("gitignore.erb", ".gitignore")
    save_file("Gemfile.erb",   "Gemfile")
    save_file("gemspec.erb",   "#{@ggem.name}.gemspec")
    save_file("README.md.erb", "README.md")
    save_file("LICENSE.erb",   "LICENSE")

    save_file("lib.rb.erb",         "lib/#{@ggem.ruby_name}.rb")
    save_file("lib_version.rb.erb", "lib/#{@ggem.ruby_name}/version.rb")

    save_file("test_helper.rb.erb",          "test/helper.rb")
    save_file("test_support_factory.rb.erb", "test/support/factory.rb")

    save_empty_file("log/.keep")
    save_empty_file("test/system/.keep")
    save_empty_file("test/unit/.keep")
    save_empty_file("tmp/.keep")
  end

  private

  def save_folder(relative_path = nil)
    path = File.join([@ggem.path, relative_path].compact)
    FileUtils.mkdir_p(path)
  end

  def save_empty_file(relative_path)
    path = File.join(@ggem.path, relative_path)
    FileUtils.touch(path)
  end

  def save_file(source, output)
    source_file = File.join(File.dirname(__FILE__), "template_file", source)
    output_file = File.join(@ggem.root_path, @ggem.name, output)

    if File.exist?(source_file)
      FileUtils.mkdir_p(File.dirname(output_file))
      erb = ERB.new(File.read(source_file))
      File.open(output_file, "w"){ |f| f << erb.result(binding) }
    else
      raise ArgumentError, "the source file `#{source_file}` does not exist"
    end
  end
end
