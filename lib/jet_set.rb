require 'hypo'
require 'sequel'
require 'sequel/extensions/inflector'
require 'jet_set/environment'
require 'jet_set/mapping'
require 'jet_set/validations'
require 'jet_set/validation_error'
require 'jet_set/version'

module JetSet
  Sequel.extension :inflector
  include JetSet::Environment

  module_function :init, :open_session, :register_session, :map
end
