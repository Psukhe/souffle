module Souffle
  # A system description with nodes and the statemachine to manage them.
  class System
    attr_reader :nodes, :root, :provider

    state_machine :state, :initial => :uninitialized do
      before_transition :uninitialized => any - :uninitialized,
        :do => :initialize_provider

      around_transition do |system, transition, block|
        start = Time.now
        block.call
        system.time_used += Time.now - start
      end
    end

    # Creates a new souffle system, defaulting to using Vagrant as a provider.
    # 
    # @param [ String ] provider The provider to use for the given system.
    def initialize(provider="Vagrant")
      initialize_provider(provider)
      super() # NOTE: This is here to initialize state_machine.
    end

    def initialize_provider(provider)
      @provider = Souffle::Provider.const_get(provider.to_sym).new
    rescue
      raise Souffle::Exceptions::InvalidProvider,
        "The provider Souffle::Provider::#{provider} does not exist."
    end

    # Proxy to the provider setup routine.
    def setup_provider
      @provider.setup
    end

    # Adds the root node to the system.
    # 
    # @param [ Souffle::Node ] node The node to become to root node.
    def root=(node)
      @root = node
    end

    # Adds a node to the system tree.
    # 
    # @param [ Souffle::Node ] node The node to add into the tree.
    def add(node)
      if root.nil?
        raise Souffle::Exceptions::RootNodeIsNil,
        "Root node cannot be nil and must be declared before adding new nodes."
      end
      @root.add_child(node)
      # TODO: Add dependency checking for child nodes.
      # needs to be intelligent.
    end

  end
end
