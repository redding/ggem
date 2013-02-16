# this file is automatically required when you run `assert`
# put any test helpers here

# add the root dir to the load path
$LOAD_PATH.unshift(File.expand_path("../..", __FILE__))

class Assert::Context

  TMP_PATH = File.expand_path "../../tmp", __FILE__

  def self.create_paths(name_set)
    called_from = caller.first
    folders = name_set.expected_folders
    files = name_set.expected_files

    paths = (folders + files).collect{|p| File.join(TMP_PATH, name_set.name, p)}
    macro_name =  "create the paths: #{paths.join(', ')}"

    Assert::Macro.new(macro_name) do
      paths.flatten.each do |path|
        should "create the path '#{path}'", called_from do
          assert File.exists?(path), "'#{path}' does not exist"
        end
      end
    end

  end

  def self.generate_name_set(name_set)
    called_from = caller.first
    macro_name =  "generate the name_set: #{name_set.inspect}"

    Assert::Macro.new(macro_name) do
      name_set.variations.each do |variation|
        [:name, :module_name, :ruby_name].each do |name_type|
          should "know its :#{name_type} given '#{variation}'", called_from do
            the_gem = GGem::Gem.new(TMP_PATH, variation)
            assert_equal name_set.send(name_type), the_gem.send(name_type)
          end
        end
      end
    end

  end

end


