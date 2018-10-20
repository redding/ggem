# this file is automatically required when you run `assert`
# put any test helpers here

# add the root dir to the load path
require "pathname"
ROOT_PATH = Pathname.new(File.expand_path("../..", __FILE__))
$LOAD_PATH.unshift(ROOT_PATH.to_s)
TMP_PATH = ROOT_PATH.join("tmp")
TEST_SUPPORT_PATH = ROOT_PATH.join("test/support")

# require pry for debugging (`binding.pry`)
require "pry"

require "test/support/factory"

# 1.8.7 backfills

# Array#sample
if !(a = Array.new).respond_to?(:sample) && a.respond_to?(:choice)
  class Array
    alias_method :sample, :choice
  end
end
