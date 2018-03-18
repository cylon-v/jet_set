require 'hypo'
require 'sequel'
require 'jet_set/version'
require 'jet_set/mapper'
require 'jet_set/proxy_factory'
require 'jet_set/session'
require 'jet_set/mapping'
require 'jet_set/entity_mapping'
require 'jet_set/query_parser'
require 'jet_set/dependency_graph'

module JetSet
  # Initializes JetSet environment.
  # Params:
  # +mapping+:: JetSet mapping definition. Instance of JetSet::Mapping class.
  # +container+:: (optional) Existing Hypo::Container instance.
  def self.init(mapping, container = Hypo::Container.new)
    @container = container

    @container.register_instance(mapping, :mapping)

    @container.register(JetSet::ProxyFactory, :proxy_factory)
      .using_lifetime(:singleton)

    @container.register(JetSet::Mapper, :mapper)
      .using_lifetime(:singleton)

    @container.register(JetSet::QueryParser, :query_parser)
      .using_lifetime(:singleton)

    @container.register(JetSet::DependencyGraph, :dependency_graph)
      .using_lifetime(:transient)
  end

  # Creates JetSet session and registers it in Hypo container.
  # Params:
  # +scope+:: a name of registered component which manages the session lifetime.
  def self.register_session(scope = nil)
    session_component = @container.register(JetSet::Session, :session)

    if scope.nil?
      @container.register_instance(nil, :session_scope)
      session_component.use_lifetime(:transient)
    else
      @container.register_instance(scope, :session_scope)
      session_component.use_lifetime(:scope).bind_to(scope)
    end
  end

  # Creates JetSet session and registers it in Hypo container.
  # Params:
  # +connection+:: Sequel connection.
  # +scope+:: a name of registered component which manages the session lifetime.
  # Returns the session object.
  def self.open_session(connection, scope = nil)
    @container.register_instance(connection, :connection)

    register_session(scope)
    @container.resolve(:session)
  end
end
