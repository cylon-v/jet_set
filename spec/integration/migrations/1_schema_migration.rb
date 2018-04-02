require 'sequel'

Sequel.migration do
  up do
    create_table(:customers) do
      primary_key :id
      String :first_name
      String :last_name
    end

    create_table(:invoices) do
      primary_key :id
      Integer :subscription_id
      DateTime :created_at
      Boolean :paid
      Decimal :amount
    end

    create_table(:line_items) do
      primary_key :id
      Integer :invoice_id
      DateTime :created_at
      Integer :quantity
      Decimal :price
    end

    create_table(:plans) do
      primary_key :id
      String :name
      Decimal :price
    end

    create_table(:subscriptions) do
      primary_key :id
      Integer :plan_id
      Integer :customer_id
      Boolean :active
      DateTime :started_at
    end

    create_table(:groups) do
      primary_key :id
      String :name
    end

    create_table(:customer_groups) do
      Integer :customer_id
      Integer :group_id
    end
  end

  down do
    drop_table(:customers)
    drop_table(:invoices)
    drop_table(:line_items)
    drop_table(:plans)
    drop_table(:subscriptions)
  end
end