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
      @name = name.gsub(/([A-Z])([a-z])/, '-\1\2').sub(/^-/, '').downcase
    end

    def module_name
      @module_name ||= transform_name {|part| part.capitalize }
    end
    def ruby_name
      @ruby_name ||= transform_name('_') {|part| part.downcase }
    end

    def save
      Template.new(self).save
    end

    private

    def transform_name(glue = nil, &block)
      self.name.split(/[_-]/).collect do |part|
        yield part if block_given?
      end.join(glue)
    end

  end
end