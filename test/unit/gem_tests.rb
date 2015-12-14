require "assert"
require "ggem/gem"

require 'ggem/clirb'

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
        @gem_class.new(TMP_PATH, [nil, ''].choice)
      end
    end

    # most of the gem's behavior is covered in the system tests

  end

  class CLITests < UnitTests
    desc "CLI"
    setup do
      @name = Factory.string

      @path = Factory.dir_path
      Assert.stub(Dir, :pwd){ @path }

      @new_called_with = []
      @gem_spy         = GemSpy.new
      Assert.stub(@gem_class, :new) do |*args|
        @new_called_with = args
        @gem_spy
      end

      @stdout = IOSpy.new
      @cli = CLI.new([@name], @stdout)
    end
    subject{ @cli }

    should have_readers :clirb

    should "know its CLI.RB" do
      assert_instance_of GGem::CLIRB, subject.clirb
    end

    should "know its help" do
      exp = "Usage: ggem generate [options] GEM-NAME\n\n" \
            "Options: #{subject.clirb}"
      assert_equal exp, subject.help
    end

    should "parse its args when `init`" do
      subject.init
      assert_equal [@name], subject.clirb.args
    end

    should "init and save a gem when run" do
      subject.init
      subject.run

      assert_equal [@path, @name], @new_called_with
      assert_true @gem_spy.save_called

      exp = "created gem and initialized git repo in #{@gem_spy.path}\n"
      assert_equal exp, @stdout.read
    end

    should "re-raise a specific argument error on gem 'no name' errors" do
      Assert.stub(@gem_class, :new) { raise NoNameError }
      err = nil
      begin
        cli = CLI.new([])
        cli.init
        cli.run
      rescue ArgumentError => err
      end

      assert_not_nil err
      exp = "GEM-NAME must be provided"
      assert_equal exp, err.message
      assert_not_empty err.backtrace
    end

  end

  class GemSpy
    attr_reader :save_called

    def initialize
      @save_called = false
    end

    def save!
      @save_called = true
      self
    end

    def path
      @path ||= Factory.path
    end
  end

  class IOSpy
    def initialize
      @io = StringIO.new
    end

    def puts(message)
      @io.puts message
    end

    def read
      @io.rewind
      @io.read
    end
  end

end
