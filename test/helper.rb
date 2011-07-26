# this file is automatically required in when you require 'test_belt'
# put test helpers here
require 'ggem'

class Test::Unit::TestCase
  TMP_PATH = File.expand_path("#{File.dirname(__FILE__)}/../tmp")

  class << self

    def should_generate_name_set(name_set)
      name_set.variations.each do |variation|
        [:name, :module_name, :ruby_name].each do |name_type|
          should "know its :#{name_type} given '#{variation}'" do
            the_gem = GGem::Gem.new(TMP_PATH, variation)
            assert_equal name_set.send(name_type), the_gem.send(name_type)
          end
        end
      end
    end

    def should_create_paths(*paths)
      paths.flatten.each do |path|
        should "create the path '#{path}'" do
          assert File.exists?(path), "'#{path}' does not exist"
        end
      end
    end

  end
end


