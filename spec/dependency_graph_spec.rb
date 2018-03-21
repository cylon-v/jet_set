require 'spec_helper'
require 'jet_set/dependency_graph'
require 'samples/mapping'
require 'samples/domain/plan'
require 'samples/domain/customer'
require 'samples/domain/subscription'
require 'samples/domain/invoice'
require 'samples/domain/line_item'

RSpec.describe 'DependencyGraph' do
  before :all do
    mapping = Mapping.load_mapping
    @dependency_graph = JetSet::DependencyGraph.new(mapping)
  end

  describe 'order' do
    it 'orders entities according their dependencies' do
      subscription = Subscription.new
      plan = Plan.new
      invoice = Invoice.new
      line_item = LineItem.new

      unordered = [line_item, invoice, subscription, plan]
      expected_order = [plan, subscription, invoice, line_item]

      expect(@dependency_graph.order(unordered)).to eq(expected_order)
    end
  end
end