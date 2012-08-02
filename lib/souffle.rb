$:.unshift File.dirname(__FILE__)
require 'yajl'
require 'eventmachine'

# An orchestrator for setting up isolated chef-managed systems.
module Souffle
  # The current souffle version.
  VERSION = "0.0.1"
end

require 'souffle/log'
require 'souffle/exceptions'
require 'souffle/config'
require 'souffle/daemon'
require 'souffle/providers'
require 'souffle/node'
require 'souffle/system'
require 'souffle/provisioner'
