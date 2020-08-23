require "fileutils"
require "ggem/template"

module GGem; end
class GGem::Gem
  NoNameError = Class.new(ArgumentError)

  attr_reader :root_path, :name

  def initialize(path, name)
    raise NoNameError if name.to_s.empty?
    @root_path, self.name = path, name
  end

  def save!
    GGem::Template.new(self).save
    self
  end

  def path
    File.join(@root_path, @name)
  end

  def name=(name)
    @name = normalize_name(name)
  end

  def module_name
    transforms = {
      "_" => "",
      "-" => ""
    }
    @module_name ||= transform_name(transforms){ |part| part.capitalize }
  end

  def ruby_name
    @ruby_name ||= transform_name{ |part| part.downcase }
  end

  private

  def normalize_name(name)
    und_camelcs = [/([A-Z])([a-z])/, '_\1\2']
    rm_dup_und  = [/_+/, "_"]
    rm_lead_und = [/^_/, "" ]
    name.gsub(*und_camelcs).gsub(*rm_dup_und).sub(*rm_lead_und).downcase
  end

  def transform_name(conditions = {}, &block)
    n = (block ? block.call(self.name) : self.name)
    conditions.each do |on, glue|
      if (a = n.split(on)).size > 1
        n = a.map{ |part| block.call(part) if block }.join(glue)
      end
    end
    n
  end
end
