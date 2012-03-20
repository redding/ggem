require "assert"
require "name_set"

require "ggem/gem"

module GGem
  class GGemTest < Assert::Context
    desc "GGem::Gem"
  end

  class RootPathTest < GGemTest
    before { @gem = Gem.new(TMP_PATH, 'a-gem') }

    should "know its root path" do
      assert_equal TMP_PATH, @gem.root_path
    end

    should "know its path" do
      assert_equal File.join(TMP_PATH, 'a-gem'), @gem.path
    end
  end

  class NameTest < GGemTest
    [ GGem::NameSet::Simple,
      GGem::NameSet::Underscored,
      GGem::NameSet::HyphenatedOther
    ].each do |ns|
      should generate_name_set(ns.new)
    end
  end

  class SaveTest < GGemTest
    NS_SIMPLE = GGem::NameSet::Simple.new
    NS_UNDER  = GGem::NameSet::Underscored.new
    NS_HYPHEN = GGem::NameSet::HyphenatedOther.new

    desc "after it's been saved"
    setup_once do
      FileUtils.mkdir_p(TMP_PATH)
      Gem.new(TMP_PATH, NS_SIMPLE.variations.first).save
      Gem.new(TMP_PATH, NS_UNDER.variations.first).save
      Gem.new(TMP_PATH, NS_HYPHEN.variations.first).save
    end
    teardown_once do
      FileUtils.rm_rf(TMP_PATH)
    end

    should create_paths((NS_SIMPLE.expected_folders + NS_SIMPLE.expected_files).collect do |p|
      File.join(TMP_PATH, NS_SIMPLE.name, p)
    end)

    should create_paths((NS_UNDER.expected_folders + NS_UNDER.expected_files).collect do |p|
      File.join(TMP_PATH, NS_UNDER.name, p)
    end)

    should create_paths((NS_HYPHEN.expected_folders + NS_HYPHEN.expected_files).collect do |p|
      File.join(TMP_PATH, NS_HYPHEN.name, p)
    end)

    should "init a git repo in the gem path" do
      assert File.exists?(File.join(TMP_PATH, NS_SIMPLE.name, '.git')), ".git repo config doesn't exist"
    end
  end

end
