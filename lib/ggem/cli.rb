require 'quickl'
require 'ggem'
require "ggem/version"

module GGemCLI

  #
  # ggem command line tool
  #
  # SYNOPSIS
  #   #{command_name} [options] GEM_NAME
  #
  # OPTIONS
  # #{summarized_options}
  #
  # DESCRIPTION
  #   This is a command line tool for using ggem
  #
  class Ggem < Quickl::Command(__FILE__, __LINE__)

    VERSION = GGem::VERSION

    # Install options
    options do |opt|

      @ggem_cli_opts = {}

      opt.on_tail('-h', '--help', "Show this help message") do
        raise Quickl::Help
      end

      opt.on_tail('-v', '--version', 'Show version and exit') do
        raise Quickl::Exit, "#{Quickl.program_name} #{VERSION}"
      end

    end

    # Run the command
    def execute(args)
      raise Quickl::Help if args.size < 1
      g = GGem::Gem.new(`pwd`.strip, *args)
      g.save
      puts "created gem and initialized git repo in #{g.path}"
    end

  end

end
