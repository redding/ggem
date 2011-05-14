require "test/helper"
require "test/name_set"

module GGem
  class GGemTest < Test::Unit::TestCase
    include TestBelt

    context "GGem::Gem"
  end

  class RootPathTest < GGemTest
    should "know its root path" do
      assert_equal TMP_PATH, Gem.new(TMP_PATH, 'a-gem').root_path
    end
  end

  class NameTest < GGemTest
    [ GGem::NameSet::Simple,
      GGem::NameSet::Underscored,
      GGem::NameSet::HyphenatedOther
    ].each do |ns|
      should_generate_name_set(ns.new)
    end
  end

  class SaveTest < GGemTest
    NS = GGem::NameSet::Simple.new

    context "after it's been saved"
    setup_once do
      FileUtils.mkdir_p(TMP_PATH)
      Gem.new(TMP_PATH, NS.variations.first).save
    end
    teardown_once do
      FileUtils.rm_rf(TMP_PATH)
    end

    should_create_paths((NS.expected_folders + NS.expected_files).collect do |p|
      File.join(TMP_PATH, NS.name, p)
    end)
  end

end