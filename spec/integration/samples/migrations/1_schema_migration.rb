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
      Double :amount
    end

    create_table(:line_items) do
      primary_key :id
      Integer :invoice_id
      DateTime :created_at
      Double :price
    end

    create_table(:plans) do
      primary_key :id
      String :name
      Double :price
    end

    create_table(:subscriptions) do
      primary_key :id
      Integer :plan_id
      Integer :user_id
      Boolean :active
      DateTime :started_at
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