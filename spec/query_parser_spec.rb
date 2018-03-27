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
          g.* AS entity group,
          c.* AS ENTITY customer
        FROM groups g
          INNER JOIN customer_groups cg ON cg.group_id = g.id
        WHERE cg.customer_id IN :customer_ids
      SQL

      it 'returns a query where "ENTITY" statements replaced with column names according to the mapping' do
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

    describe 'when result set is limited with 1 row' do
      expr = <<~SQL
        SELECT
          g.* AS ENTITY group
        FROM groups g
        LIMIT 1
      SQL

      it 'returns a query which marked as returns_single_item?' do
        query = @query_parser.parse(expr)
        expect(query.returns_single_item?).to eql(true)
      end
    end

    describe 'when result set is not limited' do
      expr = <<~SQL
        SELECT
          g.* AS ENTITY group
        FROM groups g
      SQL

      it 'returns a query which is not marked as returns_single_item?' do
        query = @query_parser.parse(expr)
        expect(query.returns_single_item?).to eql(false)
      end
    end

    describe 'when result set is limited with more than 1 row' do
      expr = <<~SQL
        SELECT
          g.* AS ENTITY group
        FROM groups g
        LIMIT 10
      SQL

      it 'returns a query which marked as returns_single_item?' do
        query = @query_parser.parse(expr)
        expect(query.returns_single_item?).to eql(false)
      end
    end

    describe 'when nested result set is limited with 1 row' do
      expr = <<~SQL
        SELECT
          g.* AS ENTITY group
        FROM groups g
          INNER JOIN (SELECT id FROM users LIMIT 10) u ON g.owner = u.id
      SQL

      it 'returns a query which marked as returns_single_item?' do
        query = @query_parser.parse(expr)
        expect(query.returns_single_item?).to eql(false)
      end
    end
  end
end