module GGem
  module NameSet


    class Base
      attr_reader :variations, :name, :module_name, :ruby_name

      def expected_folders
        [ '',
          'lib',
          "lib/#{@ruby_name}",
          'test'
        ]
      end

      def expected_files
        [ ".gitignore",
          "Gemfile",
          "#{@name}.gemspec",
          "Rakefile",
          "README.md",
          "LICENSE",

          "lib/#{@ruby_name}.rb",
          "lib/#{@ruby_name}/version.rb",

          "test/helper.rb",
          "test/irb.rb",
          "test/#{@ruby_name}_test.rb"
        ]
      end
    end


    class Simple < Base
      def initialize
        @variations = ['simple']
        @name        = 'simple'
        @module_name = 'Simple'
        @ruby_name   = 'simple'
      end
    end


    class Underscored < Base
      def initialize
        @variations = ['my_gem', 'my__gem', 'MyGem', 'myGem', 'My_Gem']
        @name        = 'my_gem'
        @module_name = 'MyGem'
        @ruby_name   = 'my_gem'
      end
    end


    class HyphenatedOther < Base
      def initialize
        @variations = ['my-gem']
        @name        = 'my-gem'
        @module_name = 'My::Gem'
        @ruby_name   = 'my/gem'
      end
    end


  end
end
