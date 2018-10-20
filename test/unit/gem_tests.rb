require "assert"
require "ggem/gem"

class GGem::Gem

  class UnitTests < Assert::Context
    desc "GGem::Gem"
    setup do
      @gem_class = GGem::Gem
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @gem_name = Factory.string
      @gem = @gem_class.new(TMP_PATH, @gem_name)
    end
    subject{ @gem }

    should have_readers :root_path, :name
    should have_imeths  :save!, :path, :name=, :module_name, :ruby_name

    should "know its root path and path" do
      assert_equal TMP_PATH, subject.root_path
      assert_equal File.join(TMP_PATH, @gem_name), subject.path
    end

    should "complain if no name is provided" do
      assert_raises(NoNameError) do
        @gem_class.new(TMP_PATH, [nil, ""].sample)
      end
    end

    # most of the gem"s behavior is covered in the system tests

  end

end
