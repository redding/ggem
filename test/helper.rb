# frozen_string_literal: true

# This file is automatically required when you run `assert`; put any test
# helpers here.

# Add the root dir to the load path.
require "pathname"
ROOT_PATH = Pathname.new(File.expand_path("../..", __FILE__))
$LOAD_PATH.unshift(ROOT_PATH.to_s)
TMP_PATH = ROOT_PATH.join("tmp")
TEST_SUPPORT_PATH = ROOT_PATH.join("test/support")

# Require pry for debugging (`binding.pry`).
require "pry"

require "test/support/factory"
