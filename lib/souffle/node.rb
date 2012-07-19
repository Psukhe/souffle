module Souffle
  class Node; end
end

require 'souffle/node/runlist_item'
require 'souffle/node/runlist'

module Souffle
  # A node object that's part of a given system.
  class Node
    attr_accessor :dependencies, :run_list, :parent
    attr_reader :children

    # state_machine :initial => :nonexistant do
    #   after_transition any => :creating, :do => :create
    #   after_transition any => :

    #   event :created do
    #     transition :creating => :configuring
    #   end

    #   event :configuring do
    #     transition :

    #   event :started do
    #     transition :starting => :initializing
    # end

    # Creates a new souffle node with bare dependencies and run_list.
    def initialize
      @dependencies = Souffle::Node::RunList.new
      @run_list = Souffle::Node::RunList.new
      @parent = nil
      @children = []
    end

    # Check whether or not a given node depends on another node.
    # 
    # @param [ Souffle::Node ] node Check to see whether this node depends
    # 
    # @return [ true,false ] Whether or not this node depends on the given.
    def depends_on?(node)
      depends = false
      self.dependencies.each do |d|
        if node.run_list.include? d
          depends = true
        end
      end
      depends
    end

    # Adds a child node to the current node.
    # 
    # @param [ Souffle::Node ] node The node to add as a child.
    # 
    # @raise [ InvaidChild ] Children must have dependencies and a run_list.
    def add_child(node)
      unless node.respond_to?(:dependencies) && node.respond_to?(:run_list)
        raise Souffle::Exceptions::InvalidChild,
          "Child must act as a Souffle::Node"
      end
      node.parent = self
      @children.push(node)
    end
  end
end
