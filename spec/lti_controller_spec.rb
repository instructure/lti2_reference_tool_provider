require_relative 'lti_spec_helper'

describe LtiController do
  include_context 'lti_spec_helper'

  def app
    LtiController
  end

  describe '/register' do

    let(:tcp_url){ '/tool-consumer-profile' }
    let(:return_url){ '/return-url' }

    context 'successful tool proxy registration' do

      before(:each) do
        HTTParty.stub(:get).and_return(tool_consumer_profile.to_json)
        HTTParty.stub(:post).and_return(tool_proxy_response)
      end

      it 'registers a tool proxy' do
        http_party = class_double(HTTParty).as_stubbed_const
        expect(http_party).to receive_messages(get: tool_consumer_profile.to_json)
        expect(http_party).to receive_messages(post: tool_proxy_response)
        post '/register', {tc_profile_url: tcp_url,
                           launch_presentation_return_url: return_url}
      end

      it 'redirects to the launch_presentation_return_url' do
        post '/register', {tc_profile_url: tcp_url,
                           launch_presentation_return_url: return_url}
        expect(URI.parse(last_response.original_headers['Location']).path).to eq return_url
      end

      it 'includes status=success in redirect to launch presentation URL when successful' do
        post '/register', {tc_profile_url: tcp_url,
                           launch_presentation_return_url: return_url}
        expect(last_response.original_headers['Location']).to include("status=success")
      end

      it 'includes tool proxy guid in redirect to launch presentation URL when successful' do
        post '/register', {tc_profile_url: tcp_url,
                           launch_presentation_return_url: return_url}
        expect(last_response.original_headers['Location']).to include("tool_proxy_guid=#{tool_proxy_guid}")
      end

      it 'persists a tool proxy' do
        tp_count = ToolProxy.count
        post '/register', {tc_profile_url: tcp_url,
                           launch_presentation_return_url: return_url}
        expect(ToolProxy.count).to eq tp_count + 1
      end

      it 'sets the tool proxy guid' do
        post '/register', {tc_profile_url: tcp_url,
                           launch_presentation_return_url: return_url}
        expect(ToolProxy.last.guid).to eq tool_proxy_guid
      end

      it 'sets the tool proxy shared secret' do
        post '/register', {tc_profile_url: tcp_url,
                           launch_presentation_return_url: return_url}
        expect(ToolProxy.last.shared_secret).not_to be_blank
      end

      it "uses a 'tp_half_shared_secret' with 128 chars" do
        post '/register', {tc_profile_url: tcp_url,
                           launch_presentation_return_url: return_url}
        expect(ToolProxy.last.tp_half_shared_secret.length).to eq 128
      end

      it "prepends the 'tc_half_shared_secret' to the shared secret" do
        post '/register', {tc_profile_url: tcp_url,
                           launch_presentation_return_url: return_url}
        expect(ToolProxy.last.shared_secret).to start_with tc_half_shared_secret
      end

      it 'sets the TCP URL' do
        post '/register', {tc_profile_url: tcp_url,
                           launch_presentation_return_url: return_url}
        expect(ToolProxy.last.tcp_url).to eq tcp_url
      end
    end

    context 'unsuccessful tool proxy registration' do
      before(:each) do
        http_party = class_double(HTTParty).as_stubbed_const
        expect(http_party).to receive_messages(get: tool_consumer_profile.to_json)
        expect(http_party).to receive_messages(post: bad_tool_proxy_response)

        post '/register', {tc_profile_url: tcp_url,
                           launch_presentation_return_url: return_url}
      end

      it 'includes status=failure in redirect to launch presentation URL when not successful' do
        post '/register', {tc_profile_url: tcp_url,
                           launch_presentation_return_url: return_url}
        expect(last_response.original_headers['Location']).to include("status=failure")
      end
    end
  end

  describe '/basic-launch' do
    it 'returns 404 if tool proxy not found' do
      post '/basic-launch', params
      expect(last_response).to be_not_found
    end

    it 'returns 401 if OAuth 1 signature is invalid' do
      ToolProxy.create!(guid: tool_proxy_guid,
                        shared_secret: secret,
                        tp_half_shared_secret: secret,
                        tcp_url: 'test.com',
                        base_url: 'base.url.com')
      post '/basic-launch', params
      expect(last_response).to be_unauthorized
    end
  end
end
