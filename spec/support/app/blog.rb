class Article < McCracken::Resource
  self.type = :articles
  mccracken.response_key_format = :dasherize

  has_one :author
  has_many :comments

  attribute :title, :string
end

class Person < McCracken::Resource
  self.type = :people
  mccracken.response_key_format = :dasherize
  has_many :articles

  attribute :first_name, String
  attribute :last_name, :string
  attribute :twitter, :string
  attribute :created_at, :time, default: -> { Time.now }, serialize: ->(val) { val.to_s }
  attribute :post_count, :integer
  attribute :meta, :hash
end

class Comment < McCracken::Resource
  self.type = :comments
  mccracken.response_key_format = :dasherize
  has_one :author

  attribute(:body, ->(val) { val.to_s })
  attribute :score, :float
  attribute :created_at, :time
  attribute :is_spam, :boolean
  attribute :mentions, :string, array: true
end
