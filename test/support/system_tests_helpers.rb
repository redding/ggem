module GGem

  module SystemTestsHelpers

    def create_paths(name_set)
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

    def generate_name_set(name_set)
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

end
