require 'hypo'
require 'jet_set/version'
require 'jet_set/mapper'
require 'jet_set/proxy_factory'
require 'jet_set/session'
require 'jet_set/mapping'
require 'jet_set/entity_mapping'
require 'jet_set/query_parser'

module JetSet
  def self.init(mapping, container = Hypo::Container.new)
    @container = container
    @container.register_instance(mapping, :mapping)

    @container.register(JetSet::ProxyFactory, :proxy_factory)
      .using_lifetime(:singleton)

    @container.register(JetSet::Mapper, :mapper)
      .using_lifetime(:singleton)

    @container.register(JetSet::QueryParser, :query_parser)
      .using_lifetime(:singleton)
  end

  def self.register_session(connection, scope = nil)
    @container.register_instance(connection, :connection)
    session_component = @container.register(JetSet::Session, :session)

    if scope.nil?
      @container.register_instance(nil, :session_scope)
      session_component.use_lifetime(:transient)
    else
      @container.register_instance(scope, :session_scope)
      session_component.use_lifetime(:scope).bind_to(scope)
    end
  end

  def self.open_session(connection, scope = nil)
    register_session(connection, scope)
    @container.resolve(:session)
  end
end
