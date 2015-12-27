require 'assert'
require 'ggem'

require 'test/support/name_set'
require 'test/support/system_tests_helpers'

module GGem

  class SystemTests < Assert::Context
    extend SystemTestsHelpers

    desc "GGem"

    NS_SIMPLE = GGem::NameSet::Simple
    NS_UNDER  = GGem::NameSet::Underscored
    NS_HYPHEN = GGem::NameSet::HyphenatedOther

    [NS_SIMPLE, NS_UNDER, NS_HYPHEN].each do |ns|
      should generate_name_set(ns.new)
    end

  end

  class SaveTests < SystemTests
    desc "when saving new gems"
    setup_once do
      FileUtils.rm_rf(TMP_PATH)
      FileUtils.mkdir_p(TMP_PATH)
      GGem::Gem.new(TMP_PATH, NS_SIMPLE.new.variations.first).save!
      GGem::Gem.new(TMP_PATH, NS_UNDER.new.variations.first).save!
      GGem::Gem.new(TMP_PATH, NS_HYPHEN.new.variations.first).save!
    end
    teardown_once do
      FileUtils.rm_rf(TMP_PATH)
    end

    should create_paths(NS_SIMPLE.new)
    should create_paths(NS_UNDER.new)
    should create_paths(NS_HYPHEN.new)

  end

end
