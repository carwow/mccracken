# Registered type, non-McCracken::Resource w/ initialize
class Album
  attr_accessor :id
  attr_accessor :title

  def self.mccracken
    return @mccracken if @mccracken
    @mccracken = McCracken::Client.new
  end

  mccracken.type = :albums
  McCracken.register_type(mccracken.type, self)

  def self.mccracken_initializer(document)
    new(document)
  end

  def initialize(document)
    @id    = document.id
    @title = document.attributes[:title]
  end
end
