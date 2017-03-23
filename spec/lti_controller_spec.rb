require_relative 'lti_spec_helper'

describe LtiController do
  include_context 'lti_spec_helper'

  def app
    LtiController
  end

  describe '/register' do
    let(:tcp_url) { '/tool-consumer-profile' }
    let(:return_url) { '/return-url' }
    let(:reg_key) { 'key'}
    let(:reg_password) { 'secret' }
    let(:oauth2_access_token_url) {'http://example.com/authorization'}
    let(:reg_launch_params) do
      {
        tc_profile_url: tcp_url,
        launch_presentation_return_url: return_url,
        reg_key: reg_key,
        reg_password: reg_password,
        oauth2_access_token_url: oauth2_access_token_url
      }
    end

    before(:each) do
      allow(HTTParty).to receive(:get).with(URI.parse(tcp_url), any_args).and_return(tool_consumer_profile.to_json)
      allow(HTTParty).to receive(:post).with(URI.parse(oauth2_access_token_url), any_args).and_return(authorization_server_response)
      allow(HTTParty).to receive(:post).with(URI.parse(tool_proxy_url), any_args).and_return(tool_proxy_response)
    end

    context 'successful tool proxy registration' do
      it 'registers a tool proxy' do

        expect(HTTParty).to receive(:post)
          .with(URI.parse(tool_proxy_url), any_args)
          .and_return(tool_proxy_response)
        post '/register', reg_launch_params
      end

      it 'uses an oauth2 token to register the tool proxy' do

        expect(HTTParty).to receive(:post)
          .with(
            URI.parse(tool_proxy_url),
            hash_including(
              {
                headers: {
                  'Content-Type' => 'application/vnd.ims.lti.v2.toolproxy+json',
                  'Authorization' => "Bearer #{access_token}"
                }
              }
            )
          )
          .and_return(tool_proxy_response)
        post '/register', reg_launch_params
      end

      it 'redirects to the launch_presentation_return_url' do
        post '/register', reg_launch_params
        expect(URI.parse(last_response.original_headers['Location']).path).to eq return_url
      end

      it 'includes status=success in redirect to launch presentation URL when successful' do
        post '/register', reg_launch_params
        expect(last_response.original_headers['Location']).to include('status=success')
      end

      it 'includes tool proxy guid in redirect to launch presentation URL when successful' do
        post '/register', reg_launch_params
        expect(last_response.original_headers['Location']).to include("tool_proxy_guid=#{tool_proxy_guid}")
      end

      it 'persists a tool proxy' do
        tp_count = ToolProxy.count
        post '/register', reg_launch_params
        expect(ToolProxy.count).to eq tp_count + 1
      end

      it 'sets the tool proxy guid' do
        post '/register', reg_launch_params
        expect(ToolProxy.last.guid).to eq tool_proxy_guid
      end

      it 'sets the tool proxy shared secret' do
        post '/register', reg_launch_params
        expect(ToolProxy.last.shared_secret).not_to be_blank
      end

      it "uses a 'tp_half_shared_secret' with 128 chars" do
        post '/register', reg_launch_params
        expect(ToolProxy.last.tp_half_shared_secret.length).to eq 128
      end

      it "prepends the 'tc_half_shared_secret' to the shared secret" do
        post '/register', reg_launch_params
        expect(ToolProxy.last.shared_secret).to start_with tc_half_shared_secret
      end

      it 'sets the TCP URL' do
        post '/register', reg_launch_params
        expect(ToolProxy.last.tcp_url).to eq tcp_url
      end
    end

    context 'unsuccessful tool proxy registration' do
      before(:each) do
        allow(HTTParty).to receive(:post).with(URI.parse(tool_proxy_url), any_args).and_return(bad_tool_proxy_response)
        post '/register', reg_launch_params
      end

      it 'includes status=failure in redirect to launch presentation URL when not successful' do
        post '/register', reg_launch_params
        expect(last_response.original_headers['Location']).to include('status=failure')
      end

      it 'checks that the TCP supports required capabilities' do
        tool_consumer_profile['capability_offered'] = []
        expect(HTTParty).to receive_messages(get: tool_consumer_profile.to_json)

        post '/register', reg_launch_params
        expect(last_response.original_headers['Location']).to include('status=failure')
      end

      it 'checks that the TCP supports the oauth2 ws security profile' do
        tool_consumer_profile['security_profile'].delete_if do |p|
          p['security_profile_name'] == 'oauth2_access_token_ws_security'
        end
        expect(HTTParty).to receive_messages(get: tool_consumer_profile.to_json)

        post '/register', reg_launch_params
        expect(last_response.original_headers['Location']).to include('status=failure')
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
                        tcp_url: 'test.com',
                        base_url: 'base.url.com')
      post '/basic-launch', params
      expect(last_response).to be_unauthorized
    end
  end
end
