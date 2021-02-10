# frozen_string_literal: true

describe McCracken::Connection do
  pending "#get"
  pending "#post"

  describe "#url=" do
    it "reconfigures the faraday object" do
      connection = McCracken::Connection.new(url: "http://api.example.com/articles")

      expect { connection.url = "http://example.com/api/v1/articles" }
        .to change { connection.faraday.url_prefix.to_s }
        .from("http://api.example.com/articles")
        .to("http://example.com/api/v1/articles")
    end
  end

  describe "#key_format=" do
    context "when :dasherize" do
      it "underscores response body keys" do
        stub_api_request(:articles_include_author_comments)
        connection = McCracken::Connection.new(
          response_key_format: :dasherize,
          url: "http://api.example.com/articles?include=author,comments"
        )

        body = connection.get.body
        keys = body[:included].first[:attributes].keys
        expect(keys).to eq(
          %i[first_name last_name twitter post_count created_at meta]
        )
      end

      it "formats request body keys" do
        url = "http://api.example.com/people/9"
        connection = McCracken::Connection.new(response_key_format: :dasherize, url: url)

        json = create_payload(:people, {
          first_name: "Chauncy",
          last_name: "Tester",
          twitter: "ChauncyTester"
        }, id: 9)

        dasherized_json = create_payload(:people, {
          "first-name" => "Chauncy",
          "last-name" => "Tester",
          "twitter" => "ChauncyTester"
        }, id: 9)

        stub = stub_request(:post, url)
          .with(body: JSON.dump(dasherized_json))
          .to_return(body: JSON.dump(dasherized_json))

        connection.post(body: json)
        expect(stub).to have_been_requested
      end
    end

    context "when :camelize" do
      it "underscores response body keys" do
        stub_api_request(:articles_include_author)
        connection = McCracken::Connection.new(
          response_key_format: :camelize,
          url: "http://api.example.com/articles?include=author"
        )
        body = connection.get.body
        keys = body[:included].first[:attributes].keys
        expect(keys).to eq(%i[first_name last_name twitter])
      end

      it "formats request body keys" do
        url = "http://api.example.com/people/9"
        connection = McCracken::Connection.new(response_key_format: :camelize, url: url)

        json = create_payload(:people, {
          first_name: "Chauncy",
          last_name: "Tester",
          twitter: "ChauncyTester"
        }, id: 9)

        dasherized_json = create_payload(:people, {
          "firstName" => "Chauncy",
          "lastName" => "Tester",
          "twitter" => "ChauncyTester"
        }, id: 9)

        stub = stub_request(:post, url)
          .with(body: JSON.dump(dasherized_json))
          .to_return(body: JSON.dump(dasherized_json))

        connection.post(body: json)
        expect(stub).to have_been_requested
      end
    end
  end

  describe "#initialize" do
    before do
      stub_const "MyRackApp", Class.new do
        def call(_env)
          [200, {"Content-Type" => "text/html"}, ["hello world"]]
        end
      end
    end

    it "configues the faraday connection" do
      connection = McCracken::Connection.new(url: "http://example.com")
      expect(connection.faraday.url_prefix.to_s).to eq "http://example.com/"
    end

    context "when passing a block" do
      it "configures faraday middleware" do
        connection = McCracken::Connection.new(url: "http://example.com") { |c|
          c.use TestMiddleware
        }

        expect(connection.faraday.builder.handlers).to include TestMiddleware
        expect(connection.faraday.builder.adapter).to eq Faraday::Adapter::NetHttp
      end
    end

    context "with a custom adapter" do
      it "configures faraday middleware" do
        connection = McCracken::Connection.new(adapter: :net_http_persistent)

        expect(connection.faraday.builder.adapter).to eq Faraday::Adapter::NetHttpPersistent
      end
    end

    context "with a custom adapter with arguments" do
      it "configures faraday middleware" do
        connection = McCracken::Connection.new(adapter: [:rack, MyRackApp.new])

        expect(connection.faraday.builder.adapter).to eq Faraday::Adapter::Rack
      end
    end
  end
end
