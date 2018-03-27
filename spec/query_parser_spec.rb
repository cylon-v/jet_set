require 'spec_helper'
require 'samples/mapping'
require 'jet_set/query_parser'

RSpec.describe 'QueryParser' do
  before :all do
    mapping = Mapping.load_mapping
    @query_parser = JetSet::QueryParser.new(mapping)
  end

  describe 'parse' do
    describe 'common case' do
      expr = <<~SQL
        SELECT
          g.* AS ENTITY group,
          c.* AS ENTITY customer
        FROM groups g
          INNER JOIN customer_groups cg ON cg.group_id = g.id
        WHERE cg.customer_id IN :customer_ids
      SQL

      it 'replaces "ENTITY" statements with column names according to the mapping' do
        query = @query_parser.parse(expr)
        expected_sql = <<~SQL
          SELECT
            g.id AS group__id,
            g.name AS group__name,
            c.id AS customer__id,
            c.first_name AS customer__first_name,
            c.last_name AS customer__last_name
          FROM groups g
            INNER JOIN customer_groups cg ON cg.group_id = g.id
          WHERE cg.customer_id IN :customer_ids
        SQL
        expect(query.sql).to eql(expected_sql)
      end
    end
  end
end