require 'rubygems'
require 'test_belt'
require 'test/env'

class Test::Unit::TestCase
  class << self

    def should_generate_given(given, expectations)
      context "given the name '#{given}'" do
        setup do
          @gem = SimpleGem::Gem.new(@path, given)
        end

        expectations.each do |k,v|
          should "know its #{k}" do
            assert_equal v, @gem.send(k)
          end
        end
      end
    end

    def should_create_files(*path_to_files)
      should "create: \n#{path_to_files.flatten.join(",\n")}" do
        path_to_files.flatten.each do |path_to_file|
          assert File.exists?(path_to_file), "'#{path_to_file}' does not exist"
        end
      end
    end

  end
end


