require 'spec_helper'

describe McCracken::ResponseMapper do
  describe '#jsonapi_resources' do
    it 'exposes all of the JSONAPI resources in the response' do
      json = response_json(:albums_include_artist)
      mapper = McCracken::ResponseMapper.new(json)

      types = mapper.jsonapi_resources.map{ |r| r[:type] }.uniq
      expect(types).to eq %w(albums artists)
    end
  end

  context 'when processing a collection' do
    it 'sets top-level jsonapi "info" on the collection' do
      stub_api_request(:albums)
      document   = Album.mccracken.agent.get(path: '/albums').body
      collection = McCracken::ResponseMapper.new(document).collection
      expect(collection.jsonapi[:version]).to eq "1.0"
    end

    it 'sets top-level jsonapi "links" on the collection' do
      stub_api_request(:albums)
      document   = Album.mccracken.agent.get(path: '/albums').body
      collection = McCracken::ResponseMapper.new(document).collection
      expect(collection.links[:self]).to eq "http://api.example.com/albums/"
    end

    it 'sets top-level jsonapi "meta" data on the collection' do
      stub_api_request(:albums)
      document   = Album.mccracken.agent.get(path: '/albums').body
      collection = McCracken::ResponseMapper.new(document).collection
      expect(collection.meta[:total_count]).to be 3
    end
  end

  describe 'when the type is registered' do
    context 'when processing a single resource' do
      it 'returns a "model"' do
        stub_api_request(:album_1)
        response = Album.mccracken.agent.get path: '/albums/1'

        mapper = McCracken::ResponseMapper.new(response.body)
        expect(mapper.resource).to be_an(Album)
      end
    end

    it 'returns a collection of models' do
      stub_api_request(:albums)
      response = Album.mccracken.agent.get
      mapper = McCracken::ResponseMapper.new(response.body)
      expect(mapper.collection.first).to be_an(Album)
    end
  end

  context 'when the type is not registered' do
    context 'when processing a single resource' do
      it 'returns a McCracken::Document' do
        stub_api_request(:venue_1)
        response = Venue.mccracken.agent.get path: '/venues/1'
        resource = McCracken::ResponseMapper.new(response.body).resource

        expect(resource).to be_a(McCracken::Document)
        expect(resource.id). to eq "1"
        expect(resource.type).to eq :venues
      end
    end

    it 'returns McCracken::Collection<McCracken::Document>' do
      stub_api_request(:venues)
      response = Venue.mccracken.agent.get
      mapper = McCracken::ResponseMapper.new(response.body)
      first_resource = mapper.collection.first

      expect(mapper.collection).to be_a(McCracken::Collection)
      expect(first_resource).to be_a(McCracken::Document)
      expect(first_resource.id).to eq "1"
      expect(first_resource.type).to eq :venues
    end
  end
end
