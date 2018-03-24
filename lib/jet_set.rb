require 'hypo'
require 'sequel'
require 'sequel/extensions/inflector'
require 'jet_set/version'
require 'jet_set/mapper'
require 'jet_set/entity_factory'
require 'jet_set/session'
require 'jet_set/mapping'
require 'jet_set/entity_mapping'
require 'jet_set/query_parser'
require 'jet_set/dependency_graph'

module JetSet
  Sequel.extension :inflector

  # Initializes JetSet environment.
  # Parameters:
  # +mapping+:: JetSet mapping definition. Instance of JetSet::Mapping class.
  # +container+:: (optional) Existing Hypo::Container instance.
  def self.init(mapping, container = Hypo::Container.new)
    @container = container

    @container.register_instance(mapping, :mapping)

    @container.register(JetSet::EntityFactory, :entity_factory)
      .using_lifetime(:singleton)

    @container.register(JetSet::Mapper, :mapper)
      .using_lifetime(:singleton)

    @container.register(JetSet::QueryParser, :query_parser)
      .using_lifetime(:singleton)
  end

  # Creates JetSet session and registers it in Hypo container.
  # Parameters:
  # +scope+:: a name of registered component which manages the session lifetime.
  def self.register_session(scope = nil)
    session_component = @container.register(JetSet::Session, :session)
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
  # +connection+:: Sequel connection.
  # +scope+:: a name of registered component which manages the session lifetime.
  # Returns the session object.
  def self.open_session(connection, scope = nil)
    @container.register_instance(connection, :connection)

    register_session(scope)
    @container.resolve(:session)
  end
end
