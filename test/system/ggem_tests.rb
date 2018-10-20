require "assert"
require "ggem"

require "test/support/name_set"

module GGem

  class SystemTests < Assert::Context

    NS_SIMPLE = GGem::NameSet::Simple
    NS_UNDER  = GGem::NameSet::Underscored
    NS_HYPHEN = GGem::NameSet::HyphenatedOther

    desc "GGem"

  end

  class GemTests < SystemTests
    desc "Gem"

    should "know its name attrs for various name styles (simple/underscored/hyphenated)" do
      [NS_SIMPLE, NS_UNDER, NS_HYPHEN].each do |ns|
        assert_gem_name_set(ns.new)
      end
    end

    private

    def assert_gem_name_set(name_set)
      name_set.variations.each do |variation|
        the_gem = GGem::Gem.new(TMP_PATH, variation)
        assert_equal name_set.name,        the_gem.name
        assert_equal name_set.module_name, the_gem.module_name
        assert_equal name_set.ruby_name,   the_gem.ruby_name
      end
    end

  end

  class GemSaveTests < GemTests
    setup do
      FileUtils.rm_rf(TMP_PATH)
      FileUtils.mkdir_p(TMP_PATH)
    end
    teardown do
      FileUtils.rm_rf(TMP_PATH)
    end

    should "save gems with various name styles (simple/underscored/hyphenated)" do
      [NS_SIMPLE, NS_UNDER, NS_HYPHEN].each do |ns|
        init_gem = GGem::Gem.new(TMP_PATH, ns.new.variations.first)
        gem_from_save = init_gem.save!

        assert_gem_created(ns.new)
        assert_same init_gem, gem_from_save
      end
    end

    private

    def assert_gem_created(name_set)
      folders = name_set.expected_folders
      files   = name_set.expected_files
      paths   = (folders + files).collect{ |p| File.join(TMP_PATH, name_set.name, p) }

      paths.flatten.each do |path|
        assert File.exists?(path), "`#{path}` does not exist"
      end
    end

  end

end
