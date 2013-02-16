require "assert"
require "ggem/gem"

class GGem::Gem

  class BaseTests < Assert::Context
    desc "GGem::Gem"
    setup do
      @gem = GGem::Gem.new(TMP_PATH, 'a-gem')
    end
    subject { @gem }

    should have_readers :root_path, :name
    should have_imeths  :save!, :path, :name=, :module_name, :ruby_name

    should "know its root path and path" do
      assert_equal TMP_PATH, subject.root_path
      assert_equal File.join(TMP_PATH, 'a-gem'), subject.path
    end

  end

end
