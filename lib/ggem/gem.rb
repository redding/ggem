require 'fileutils'
require 'ggem/template'

module GGem
  class Gem

    attr_reader :root_path, :name

    def initialize(path, name)
      @root_path = path
      self.name = name
    end

    def name=(name)
      @name = name.
        gsub(/([A-Z])([a-z])/, '_\1\2').
        gsub(/_+/, '_').
        sub(/^_/, '').
        downcase
    end

    def module_name
      @module_name ||= transform_name({
        '_' => '',
        '-' => '::'
      }) {|part| part.capitalize }
    end
    def ruby_name
      @ruby_name ||= transform_name({
        '-' => '/'
      }) {|part| part.downcase }
    end

    def save
      Template.new(self).save
    end

    private

    def transform_name(conditions, &block)
      n = (block ? block.call(self.name) : self.name)
      conditions.each do |on, glue|
        if (a = n.split(on)).size > 1
          n = a.collect do |part|
            block.call(part) if block
          end.join(glue)
        end
      end
      n
    end

  end
end
