require "test/helper"

module SimpleGem
  class GemTest < Test::Unit::TestCase

    TMP_GEM_PATH = File.expand_path("#{File.dirname(__FILE__)}/../tmp")
    STD_NAME_VARIATIONS = ['simple-gem', 'SimpleGem', 'simpleGem']
    STD_NAME_EXPECTATIONS = {
      :name        => 'simple-gem',
      :module_name => 'SimpleGem',
      :ruby_name   => 'simple_gem'
    }
    STD_EXPECTED_DIRS = [
      '/',
      '/lib',
      "/lib/#{STD_NAME_EXPECTATIONS[:ruby_name]}",
      '/test'
    ]
    STD_EXPECTED_FILES = [
      "/.gitignore",
      "/Gemfile",
      "/#{STD_NAME_EXPECTATIONS[:name]}.gemspec",
      "/Rakefile",
      "/README.rdoc",

      "/lib/#{STD_NAME_EXPECTATIONS[:ruby_name]}.rb",
      "/lib/#{STD_NAME_EXPECTATIONS[:ruby_name]}/version.rb",

      "/test/helper.rb",
      "/test/env.rb",
      "/test/#{STD_NAME_EXPECTATIONS[:ruby_name]}_test.rb"
    ]

    context "A Gem" do
      should "know its root path" do
        assert_equal TMP_GEM_PATH, Gem.new(TMP_GEM_PATH, STD_NAME_EXPECTATIONS[:name]).root_path
      end

      should_generate_given 'simple_gem', STD_NAME_EXPECTATIONS.merge(:name => 'simple_gem')
      STD_NAME_VARIATIONS.each do |std_name_variation|
        should_generate_given std_name_variation, STD_NAME_EXPECTATIONS
      end

      context "when generated" do
        setup_once do
          FileUtils.mkdir_p(TMP_GEM_PATH)
          Gem.new(TMP_GEM_PATH, STD_NAME_EXPECTATIONS[:name]).generate
        end
        teardown_once do
          FileUtils.rm_rf(TMP_GEM_PATH)
        end

        should_create_files(STD_EXPECTED_DIRS.collect { |d|
          "#{TMP_GEM_PATH}/#{STD_NAME_EXPECTATIONS[:name]}#{d}"
        } + STD_EXPECTED_FILES.collect { |f|
          "#{TMP_GEM_PATH}/#{STD_NAME_EXPECTATIONS[:name]}#{f}"
        })

      end
    end

  end
end