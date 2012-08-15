$:.unshift File.dirname(__FILE__)
require 'yajl'
require 'eventmachine'
require 'em-ssh'

require 'souffle/ssh_monkey'
require 'souffle/log'
require 'souffle/exceptions'
require 'souffle/config'
require 'souffle/daemon'
require 'souffle/node'
require 'souffle/system'
require 'souffle/providers'
require 'souffle/provisioner'
