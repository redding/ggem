module GGem
  module NameSet

    class Base
      attr_reader :variations, :name, :module_name, :ruby_name

      def expected_folders
        [ '',
          'lib',
          "lib/#{@ruby_name}",
          'test',
          'test/support',
          'test/system',
          'test/unit',
          'log',
          'tmp'
        ]
      end

      def expected_files
        [ ".gitignore",
          "Gemfile",
          "#{@name}.gemspec",
          "Rakefile",
          "README.md",
          "LICENSE.txt",

          "lib/#{@ruby_name}.rb",
          "lib/#{@ruby_name}/version.rb",

          "test/helper.rb",
          "test/support/factory.rb",

          "log/.gitkeep",
          "tmp/.gitkeep",
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
        @module_name = 'MyGem'
        @ruby_name   = 'my-gem'
      end
    end

  end
end
