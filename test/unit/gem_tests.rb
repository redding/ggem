require "assert"

require "test/support/name_set"
require "ggem/gem"

class GGem::Gem
  NS_SIMPLE = GGem::NameSet::Simple
  NS_UNDER  = GGem::NameSet::Underscored
  NS_HYPHEN = GGem::NameSet::HyphenatedOther

  class BaseTests < Assert::Context
    desc "GGem::Gem"

    [ NS_SIMPLE, NS_UNDER, NS_HYPHEN ].each do |ns|
      should generate_name_set(ns.new)
    end

  end

  class RootPathTests < BaseTests
    setup do
      @gem = GGem::Gem.new(TMP_PATH, 'a-gem')
    end

    should "know its root path and path" do
      assert_equal TMP_PATH, @gem.root_path
      assert_equal File.join(TMP_PATH, 'a-gem'), @gem.path
    end

  end

  class SaveTests < BaseTests
    desc "after it's been saved"
    setup_once do
      FileUtils.mkdir_p(TMP_PATH)
      GGem::Gem.new(TMP_PATH, NS_SIMPLE.new.variations.first).save
      GGem::Gem.new(TMP_PATH, NS_UNDER.new.variations.first).save
      GGem::Gem.new(TMP_PATH, NS_HYPHEN.new.variations.first).save
    end
    teardown_once do
      FileUtils.rm_rf(TMP_PATH)
    end

    should create_paths(NS_SIMPLE.new)
    should create_paths(NS_UNDER.new)
    should create_paths(NS_HYPHEN.new)

    should "init a git repo in the gem path" do
      exp_path = File.join(TMP_PATH, NS_SIMPLE.new.name, '.git')
      assert File.exists?(exp_path), ".git repo config doesn't exist"
    end

  end

end
