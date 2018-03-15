require 'hypo'
require 'sequel'
require 'jet_set/version'
require 'jet_set/mapper'
require 'jet_set/proxy_factory'
require 'jet_set/session'
require 'jet_set/mapping'
require 'jet_set/entity_mapping'
require 'jet_set/query_parser'

module JetSet
  def self.init(mapping, connection_string, container = Hypo::Container.new)
    @container = container

    @container.register_instance(mapping, :mapping)
    @container.register_instance(connection_string, :connection_string)

    @container.register(JetSet::ProxyFactory, :proxy_factory)
      .using_lifetime(:singleton)

    @container.register(JetSet::Mapper, :mapper)
      .using_lifetime(:singleton)

    @container.register(JetSet::QueryParser, :query_parser)
      .using_lifetime(:singleton)
  end

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

  def self.open_session(scope = nil)
    register_session(scope)
    @container.resolve(:session)
  end
end
