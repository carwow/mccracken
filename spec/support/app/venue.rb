# Unregisterd, no initializer, mapper will return documents
class Venue
  def self.mccracken
    return @mccracken if @mccracken
    @mccracken = McCracken::Client.new.configure do |c|
      c.type = :venues
    end
  end
end
