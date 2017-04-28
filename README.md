# McCracken

[![Gem Version](https://badge.fury.io/rb/mccracken.svg)](https://badge.fury.io/rb/mccracken)
[![Code Climate](https://codeclimate.com/github/jgnagy/mccracken/badges/gpa.svg)](https://codeclimate.com/github/jgnagy/mccracken)
[![Test Coverage](https://codeclimate.com/github/jgnagy/mccracken/badges/coverage.svg)](https://codeclimate.com/github/jgnagy/mccracken/coverage)
[![Build Status](https://travis-ci.org/jgnagy/mccracken.svg?branch=develop)](https://travis-ci.org/jgnagy/mccracken)

A JSON API client for Ruby

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mccracken'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mccracken

## Basic Usage

```ruby
class Article < McCracken::Resource
  # This is done automatically if the tableize method is present
  self.type = :articles

  # how to process the JSON API ID. JSON API always uses strings, but McCracken defaults to :integer
  key_type :integer, #:string, ->(id){ }
  attribute :title, :string
end
```

### Registering the JSONAPI 'type'

Calling ```Article.type = :articles``` registers the class ```Article``` as the handler for JSON API resources of the type ```articles```.

When the ActiveSupport method ```tableize``` is present, this will be set automatically. A class can be bound to multiple types:

```ruby
Article.type = :articles
McCracken.register_type(:posts, Article)
```

### Querying
```ruby
articles = Article.fetch # Get some articles
article = Article.find(9) # Find an article

query = Article.fields(:title).include(:author, :comments).sort(id: :desc).filter(published: true)
query.to_params #=> {:filter=>{:published=>"true"}, :fields=>{:articles=>"title"}, :include=>"author,comments", :sort=>"-id"}
query.to_query_string #=> "fields[articles]=title&filter[published]=true&include=author,comments&sort=-id"

query.fetch # Fetch articles w/ the given query string
```

The McCracken::Resource delegates a few methods to its underlying McCracken::Connection:

#### Filtering

```ruby
query = Product.filter(min_price: 30, max_price: 65)

# its chainable
query.filter(category: 'Hats').filter(size: ['small', 'medium'])

query.to_params
#=> {:filter=>{:min_price=>"30", :max_price=>"65", :category=>"Hats", :size=>"small,medium"}}

query.fetch #=> McCracken::Collection<Product,Product>
```

#### Sorting

```ruby
query = Product.sort(created_at: :desc)

# its chainable
query.sort(:price) # defaults to ASC

query.to_params
#=> {:sort=>"-created_at,price"}

query.fetch #=> McCracken::Collection<Product,Product>
```

#### Including (Side loading related resources)

```ruby
query = Product.include(:manufacturer)

# its chainable
query.include(:vendor)

query.to_params
#=> {:include=>"manufacturer,vendor"}

query.fetch #=> McCracken::Collection<Product,Product>
```

#### Sparse Fieldsets

```ruby
query = Product.fields(products: [:name, :price])

# its chainable
query.include(:manufacturer).fields(manufacturer: [:name])

query.to_params
#=> {:fields=>{:products=>"name,price", :manufacturer=>"name"}, :include=>"manufacturer"}

query.fetch #=> McCracken::Collection<Product,Product>
```

#### All the things!
```ruby
query = Product.
  filter(min_price: 30, max_price: 65).
  includes(:manufacturer).
  sort(popularity: :desc, price: :asc).
  fields(product: ['name', 'price'], manufacturer: ['name', 'website']).
  page(number: 1, limit: 100)

query.to_params

#=> {:filter=>{:min_price=>"30", :max_price=>"65"}, :fields=>{:product=>"name,price", :manufacturer=>"name,website"}, :include=>"manufacturer", :sort=>"-popularity,price", :page=>{:limit=>10}}

query.fetch #=> McCracken::Collection<Product,Product>
```

#### Fetching a single resource

```ruby
Product.find(1) #=> product
```

### Accessing McCracken internals
Every McCracken::Resource has an internally managed client. It is accessible via ```.mccracken```

```ruby
Article.mccracken #=> McCracken::Client
Article.mccracken.path #=> base path to use for this resource. Defaults to "/" + type; i.e., "/articles"
Article.mccracken.agent #=> McCracken::Agent: the agent wraps the McCracken::Connection. It performs the low level GET/POST/PUT/PATCH/DELETE methods
Article.mccracken.query #=> McCracken::Query: a chainable query building instance
Article.mccracken.connection #=> McCracken::Connection: Small wrapper around the Farady connection
Article.mccracken.connection.response_key_format #=> :dasherize, :camelize, nil
Article.mccracken.connection.url #=> This endpoints base URL http://api.example.com/
Article.mccracken.connection.faraday #=> The faraday object for this connection
Article.mccracken.connection = SomeNewConnectionYouPrefer
Article.mccracken.connection.configure(opts) do { |faraday_conn| } #=> Feel free to reconfigure me ;D
```

### Persistence Resources
```ruby
class Article < McCracken::Resource
  attribute :title, :string
  attribute :body, :string
  attribute :created_at, :time
end
```

Creating a new resource

```ruby
article = Article.new
article.title = "This is a great read!"
article.save #=> Boolean: Will attempt to POST to /articles
article.errors?
article.errors #=> Array of errors
```

Updating a resource

```ruby
article = Article.find(9)
article.title = "This is a great read!"
article.save #=> Boolean: Will attempt to PATCH to /articles
article.errors?
article.errors #=> Array of errors
```

### Accessing Side Loaded Resources

Given the following relationship:

```ruby
class Article < McCracken::Resource
  self.type = :articles
  has_one :author
  has_many :comments

  key_type :integer
  attribute :title, :string
end

class Person < McCracken::Resource
  self.type = :people
  has_many :articles

  attribute :first_name, String
  attribute :last_name, :string
  attribute :twitter, :string
  attribute :created_at, :time, default: ->{ Time.now }, serialize: ->(val){ val.to_s }
  attribute :post_count, :integer
end

class Comment < McCracken::Resource
  self.type = :comments
  has_one :author

  attribute :body, ->(val){ val.to_s }
  attribute :score, :float
  attribute :created_at, :time
  attribute :is_spam, :boolean
  attribute :mentions, :string, array: true
end
```

**Note:** When specifying relationships in McCracken, you are specifying the JSON API type name. You'll notice below that when ```.author``` is called it returns a person object. That it is because in the HTTP response, the relationship name is ```author``` but the resource type is ```people```.

```json
{
  "data": [{
    "type": "articles",
    "id": "1",
    "attributes": {
      "title": "JSON API paints my bikeshed!"
    },
    "relationships": {
      "author": {
        "links": {
          "self": "http://example.com/articles/1/relationships/author",
          "related": "http://example.com/articles/1/author"
        },
        "data": { "type": "people", "id": "9" }
      }
    }
  }]
}
```

McCracken initializes objects for side loaded resources. Only 1 HTTP call is made.

```ruby
article = Article.include(:author, :comments).find(9)
article.author #=> Person object
article.comments #=> McCracken::Collection<Comment>

article.author.first_name #=> Chauncy
```



## Configuration

McCracken is designed to support multiple connections or API endpoints. A connection is a wrapper around Faraday::Connection that includes a few pieces of middleware for parsing and encoding requests and responses to JSON API Spec.

Setting the default connection:

```ruby
McCracken.configure(url: 'http://api.example.com') do |c|
  c.use MyCustomMiddleware
  c.use AllTheMiddlewares
end
```

Each McCracken::Resource has its own McCracken::Client. The client *copies* the default connection so its easy to set general configuration options, and overwrite them on a resource by resource basis.

```ruby
McCracken.configure(url: 'http://api.example.com', response_key_format: :dasherize)

class Kitten < McCracken::Resource
  mccracken.url = "http://api.differentsite.com"
end

# Overwritten URL
Kitten.mccracken.connection.url #=> "http://api.differentsite.com"
# Copied key format
Kitten.mccracken.connection.response_key_format #=> :dasherize

McCracken.default_connection.url #=> "http://api.example.com"
McCracken.default_connection.response_key_format #=> :dasherize
```

### Configuration Options

```ruby
McCracken.configure(url: 'http://api.example.com', response_key_format: :dasherize) do |conn|
  conn.use SomeCoolFaradayMiddleware
end
```

Two special options can be passed into ```.configure```:
* ```url``` the base url for this endpoint
* ```response_key_format``` the format of the JSONAPI response keys. Valid values are: ```:dasherize```, ```:camelize```, ```nil```

Additinally any Faraday Connection options can be passed. [Faraday::Connection options](https://github.com/lostisland/faraday/blob/master/lib/faraday/connection.rb Faraday::Connection)


## Advanced Usage

### Custom Query Builder

Since the filter param's format isn't specified in the [spec](http://jsonapi.org/format/#fetching-filtering)
this implementation uses [JSONAPI::Resource's implementation](https://github.com/cerebris/jsonapi-resources#filters)

To override, implement your own custom query builder inheriting from ```McCracken::Query```.
```McCracken::Client``` takes a Query class to use. This method could be overwritten in your Resource:

```ruby
class MyBuilder < McCracken::Query
  def filter_to_query_value
    # ... your fancier logic
  end
end

Article.mccracken.query_builder = MyBuilder
Article.mccracken.filter(:name => "Chauncy") #=> MyBuilder instance
```

### Without inheriting from McCracken::Resource

If for some reason you cannot inherit from McCracken::Resource, you can still get a lot of JSONAPI parsing functionality

```ruby
class Album
  # Just some attr accessors, NBD
  attr_accessor :id
  attr_accessor :title

  # Give Album a client to use
  def self.mccracken
    return @mccracken if @mccracken
    @mccracken = McCracken::Client.new
  end

  # Set the type, note, this is not being set on self
  mccracken.type = :albums

  # Register the type w/ mccracken
  McCracken.register_type(mccracken.type, self)

  # When you aren't inherited from McCracken::Resource, McCracken will pass a McCracken::Document to a static method called mccracken_initializer for you to initialze your record as you wish
  def self.mccracken_initializer(document)
    new(document.id, document.attributes[:title])
  end

  def initialize(id, title)
    @id    = id
    @title = title
  end
end
```

```ruby
albums = Album.mccracken.include(:songs).fetch
albums.first.title #=> An album title!
```

### Any ol' object (Register type, add mccracken_initializer)

As long as a class is registered with mccracken and it response to mccracken_initializer, McCracken will be able to initialize the object with or without a client

Extending the example above...

```ruby
class Song
  attr_reader :name
  def self.mccracken_initializer(document)
    new(document.attributes[:name])
  end

  def initialize(name)
    @name = name
  end
end

McCracken.register_type :songs, Song
```

```ruby
album = Album.mccracken.include(:songs).find(9)
album.songs #=> McCracken::Collection<Song>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jgnagy/mccracken. Base hotfixes off of the `master` branch and features off of the `develop` branch.


## TODOS
* [ ] Update Yard docs :D
* [ ] Posting/Putting relationships
* [ ] A few pending tests :/
* [ ] Collection#next (queries for next page, if pagination present)
* [ ] Related Documents/Resources taking advantage of underlying resource[links]
* [ ] Error object to wrap an individual error
* [ ] consider enumerable protocol on a query
* [ ] Handle null/empty responses...
* [ ] Pluggable pagination?
* [ ] Query#find([...]) find multiple records
