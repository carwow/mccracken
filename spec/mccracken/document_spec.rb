# frozen_string_literal: true

RSpec.describe McCracken::Document do
  describe "#relationship" do
    context "when the relationship does not exist" do
      it "raises a McCracken::RelationshipNotFound error" do
        json = response_json(:artist_9)
        artist = McCracken::Document.new(json)

        expect { artist.relationship(:foos) }
          .to raise_error(McCracken::RelationshipNotFound)
      end
    end

    context "when the relationships was not included" do
      it "raises a McCracken::RelationshipNotFound error" do
        document = McCracken::Document.new(data: {
          type: :things,
          id: "1",
          relationships: {
            foos: {
              data: [
                {type: :foos, id: "1"},
                {type: :foos, id: "2"}
              ]
            }
          }
        })

        expect { document.relationship(:foos) }
          .to raise_error(McCracken::RelationshipNotIncludedError)
      end
    end

    context "when it is a to-many relationship" do
      it "returns related documents" do
        json = response_json(:artist_9_include_albums_record_label)
        artist = McCracken::Document.new(json)
        albums = artist.relationship(:albums)

        expect(albums).to be_a(Array)
        expect(albums.first).to be_a(McCracken::Document)
      end
    end

    context "when it is a to-one relationship" do
      it "returns the related document" do
        json = response_json(:artist_9_include_albums_record_label)
        artist = McCracken::Document.new(json)

        record_label = artist.relationship(:record_label)
        expect(record_label).to be_a(McCracken::Document)
        expect(record_label.type).to be :record_labels
      end
    end
  end

  describe "#id" do
    it "returns the ID of the jsonapi resource" do
      json = response_json(:album_1_include_artist)
      document = McCracken::Document.new(json)
      expect(document.id).to eq "1"
    end
  end

  describe "#type" do
    it "returns the type of the jsonapi resource" do
      json = response_json(:album_1_include_artist)
      document = McCracken::Document.new(json)
      expect(document.type).to eq :albums
    end
  end

  describe "#attributes" do
    it "returns the attributes of the jsonapi resource" do
      json = response_json(:album_1_include_artist)
      document = McCracken::Document.new(json)
      expect(document.attributes).to eq(title: "The Crane Wife")
    end
  end

  describe "#relationships" do
    it "returns the relationships of the jsonapi resource" do
      json = response_json(:album_1_include_artist)
      document = McCracken::Document.new(json)
      expect(document.relationships).to eq(artist: {
        data: {type: "artists", id: "9"},
        links: {
          self: "http://api.example.com/albums/1/relationships/artist",
          related: "http://api.example.com/albums/1/artist"
        }
      })
    end
  end
end
