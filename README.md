# JetSet ![Build Status](https://travis-ci.org/cylon-v/jet_set.svg?branch=master)

JetSet is a data mapping framework for domain-driven developers who think that SQL is the best tool for data querying.
JetSet is built on top of [Sequel](https://github.com/jeremyevans/sequel) ORM and it's just an abstraction for making 
the persistence of mapped objects invisible.  

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jet_set'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jet_set

## Usage

### Initialization
Open DB connection, see [Sequel docs](https://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html):
```ruby
 @connection = Sequel.connect('sqlite:/') # you can connect to any DB supported by Sequel
```

Create a mapping of your model, details described [here]:
```ruby
class Mapping
  def self.load_mapping
    JetSet::map do
      entity User do
        field :first_name # reqular field
        collection :invoices, type: Invoice # "has many" association
        reference :plan, type: Plan, weak: true # "belongs to" association
      end
    end
  end
end
```

Init JetSet environment on start of your application:
```ruby
JetSet::init(Mapping.load_mapping, @container)
```

Open JetSet session:
```ruby
@jet_set = JetSet::open_session(@connection)
```
For web-applications it's reasonable to bind JetSet session to request lifetime - 
all modification operations in an MVC action can represent a ["Unit of Work"](https://martinfowler.com/eaaCatalog/unitOfWork.html).

### Object model
Using JetSet you can wrap an application domain model and purely implement "Persistence Ignorance" approach. 
The model objects are pure Ruby objects without any noisy stuff like annotations, inline mapping, etc:
```ruby
class User
  attr_reader :invoices

  def initialize(attrs = {})
    @first_name = attrs[:first_name]
    @last_name = attrs[:last_name]
    @invoices = []
  end

  def add_invoice(invoice)
    @invoices << invoice
  end
end

class Invoice
  attr_reader :created_at, :amount

  def initialize(attrs = {})
    @created_at = DateTime.now
    @amount = attrs[:amount] || 0
  end
end
```

### Object model tracking and saving
Create an objects which is described in the mapping:
```ruby
user = User.new(first_name: 'Ivan', last_name: 'Ivanov')
invoice = Invoice.new(created_at: DateTime.now, user: user, amount: 100.0)
```

Attach them to the session:
```ruby
 @session.attach(invoice, user)
```
It makes the objects tracked by JetSet.

Finalize the session:
```ruby
 @session.finalize
```
It saves all added/changed objects to the database.

### Object model loading

```ruby
user_query = <<~SQL
  SELECT
    u.* AS ENTITY user
  FROM users u
  LIMIT 1
SQL

invoices_sql = <<~SQL
  SELECT
    i.* AS ENTITY invoice
  WHERE i.user_id = :user_id
SQL

customer = @session.fetch(User, user_query) do |user|
  preload(user, :invoices, invoices_sql, user_id: user.id)
end
```
All loaded objects are already attached to the session and you can perform a changes which will be saved after the session finalization:

```ruby
customer.invoices[0].apply # changes invoice state
@session.finalize
```

Do not load your object model just for drawing a views. For showing a results just use Sequel without any object mappings:
```ruby
result = @connection[:user].where(role: 'admin').to_a
json = JSON.generate(data: result)
```   
In other words, following [CQS](https://en.wikipedia.org/wiki/Command%E2%80%93query_separation) approach you can 
load your model for a command but not for a query.

You can find more interesting examples in [JetSet integration tests](https://github.com/cylon-v/jet_set/tree/master/spec/integration).        
Also for the details please visit our [wiki].

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/jet_set.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
