require 'state_machine'

require 'souffle/polling_event'

# The system provisioning statemachine.
class Souffle::Provisioner::System
  attr_accessor :time_used, :provider

  state_machine :state, :initial => :initializing do
    after_transition any => :handling_error, :do => :error_handler
    after_transition :initializing => :creating, :do => :create
    after_transition :creating => :provisioning, :do => :provision
    after_transition any => :initializing, :do => :create

    event :initialized do
      transition :initializing => :creating
    end

    event :created do
      transition :creating => :provisioning
    end

    event :provisioned do
      transition :provisioning => :complete
    end

    event :error_occurred do
      transition any => :handling_error
    end

    event :creation_halted do
      transition any => :failed
    end

    event :reclaimed do
      transition any => :initializing
    end

    around_transition do |system, transition, block|
      start = Time.now
      block.call
      system.time_used += Time.now - start
    end
  end

  # Creates a new system using a specific provider.
  # 
  # @param [ Souffle::System ] system The system to provision.
  # @param [ Souffle::Provider::Base ] provider The provider to use.
  # @param [ Fixnum ] max_failures the maximum number of failures.
  # @param [ Fixnum ] timeout The maximum time to wait for node creation.
  def initialize(system, provider, max_failures=3, timeout=500)
    @failures = 0
    @system = system
    @provider = provider
    @time_used = 0
    @timeout = timeout
    super() # NOTE: This is here to initialize state_machine.
  end

  # Creates the system from an api or command.
  def create
    Souffle::Log.info "[#{system_tag}] Creating a new system..."
    @system.nodes.each do |node|
      node.provisioner = Souffle::Provisioner::Node.new(node)
      node.provisioner.initialized
    end
    wait_until_created
  end

  # Provisioning the system.
  # 
  # @todo We should really have these provisioned with fibers.
  def provision
    Souffle::Log.info "[#{system_tag}] Provisioning the system..."
    @system.rebalance_nodes
    @system.nodes.each do |node|
      when_parents_are_complete(node) { node.provisioner.begin_provision }
    end
    wait_until_complete
  end

  # Wait until all of the parent nodes are in a completed state and yield.
  def when_parents_are_complete(node)
    total_nodes = node.parents.size
    if total_nodes == 0
      yield if block_given?
      all_complete = true
    else
      all_complete = false
    end
    timer = EM::PeriodicTimer.new(2) do
      nodes_complete = node.parents.select do |n|
        n.provisioner.state == "complete"
      end.size

      if nodes_complete == total_nodes
        all_complete = true
        timer.cancel
        yield if block_given?
      end
    end

    EM::Timer.new(@timeout) do
      unless all_complete
        Souffle::Log.error "[#{system_tag}] Parent creation timeout reached."
        timer.cancel
        error_occurred
      end
    end
  end

  # Kills the system.
  def kill_system
    # @provider.kill(@system.nodes)
  end

  # Handles the error state and recreates the system
  def error_handler
    @failures += 1
    if @failures >= max_failures
      Souffle::Log.error "[#{system_tag}] Complete failure. Halting Creation."
      creation_halted
    else
      err_msg =  "[#{system_tag}] Error creating system. "
      err_msg << "Killing and recreating..."
      Souffle::Log.error(err_msg)
      kill_system
      reclaimed
    end
  end

  private

  # Helper function for the system tag.
  # 
  # @param [ String ] The system or global tag.
  def system_tag
    @system.try_opt(:tag)
  end

  # Wait until all of the nodes are ready to be provisioned and then continue.
  def wait_until_created
    total_nodes = @system.nodes.size
    all_created = false
    timer = EM::PeriodicTimer.new(2) do
      nodes_ready = @system.nodes.select do |n|
        n.provisioner.state == "ready_to_provision"
      end.size

      if nodes_ready == total_nodes
        all_created = true
        timer.cancel
        created
      end
    end

    EM::Timer.new(@timeout) do
      unless all_created
        Souffle::Log.error "[#{system_tag}] System creation timeout reached."
        timer.cancel
        error_occurred
      end
    end
  end

  # Wait until all of the nodes are provisioned and then continue.
  def wait_until_complete
    total_nodes = @system.nodes.size
    all_complete = false
    timer = EM::PeriodicTimer.new(2) do
      nodes_ready = @system.nodes.select do |n|
        n.provisioner.state == "complete"
      end.size

      if nodes_ready == total_nodes
        all_complete = true
        timer.cancel
        created
      end
    end

    EM::Timer.new(@timeout) do
      unless all_complete
        Souffle::Log.error "[#{system_tag}] System provision timeout reached."
        timer.cancel
        error_occurred
      end
    end
  end

end
