require 'hypo'
require 'sequel'
require 'jet_set/entity_builder'
require 'jet_set/session'
require 'jet_set/mapping'
require 'jet_set/mapper'
require 'jet_set/entity_mapping'
require 'jet_set/query_parser'
require 'jet_set/dependency_graph'

module JetSet
  module Environment
    # Initializes JetSet environment.
    # Parameters:
    # +mapping+:: JetSet mapping definition. Instance of JetSet::Mapping class.
    # +container+:: (optional) Existing Hypo::Container instance.
    def init(mapping, container = Hypo::Container.new)
      @container = container

      @container.register_instance(mapping, :mapping)

      @container.register(JetSet::EntityBuilder, :entity_builder)
        .using_lifetime(:singleton)

      @container.register(JetSet::Mapper, :mapper)
        .using_lifetime(:singleton)

      @container.register(JetSet::QueryParser, :query_parser)
        .using_lifetime(:singleton)
    end

    # Creates JetSet session and registers it in Hypo container.
    # Parameters:
    # +scope+:: a name of registered component which manages the session lifetime.
    def register_session(scope = nil)
      session_component = @container.register(JetSet::Session, :jet_set)
      dependency_graph_component = @container.register(JetSet::DependencyGraph, :dependency_graph)

      if scope.nil?
        @container.register_instance(nil, :session_scope)
        session_component.use_lifetime(:transient)
        dependency_graph_component.use_lifetime(:transient)
      else
        @container.register_instance(scope, :session_scope)
        session_component.use_lifetime(:scope).bind_to(scope)
        dependency_graph_component.use_lifetime(:scope).bind_to(scope)
      end

    end

    # Creates JetSet session and registers it in Hypo container.
    # Parameters:
    # +sequel+:: Sequel connection.
    # +scope+:: a name of registered component which manages the session lifetime.
    # Returns the session object.
    def open_session(sequel, scope = nil)
      @container.register_instance(sequel, :sequel)

      register_session(scope)
      @container.resolve(:jet_set)
    end


    # Accepts Ruby block with mapping definition.
    # Parameters:
    #   +&block+: Ruby block
    # Usage:
    #   JetSet::Mapping.new do
    #     entity Invoice do
    #       field :amount
    #       field :created_at
    #       collection :line_items
    #       reference :subscription, type: Subscription
    #     end
    #     ...
    #     entity User do
    #       field :amount
    #       field :created_at
    #       collection :line_items
    #       reference :subscription, type: Subscription
    #     end
    #   end
    def map(&block)
      unless block_given?
        raise MapperError, 'Mapping should be defined as Ruby block.'
      end

      Mapping.new(&block)
    end
  end
end