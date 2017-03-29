require_relative 'lti_spec_helper'

describe LtiController do
  include_context 'lti_spec_helper'

  def app
    LtiController
  end

  describe '/register' do

    let(:tcp_url) { '/tool-consumer-profile' }
    let(:return_url) { '/return-url' }

    context 'successful tool proxy registration' do

      before(:each) do
        allow(HTTParty).to receive(:get).and_return(tool_consumer_profile.to_json)
        allow(HTTParty).to receive(:post).and_return(tool_proxy_response)
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
    let(:tool_proxy) do
      ToolProxy.create!(guid: tool_proxy_guid,
                        shared_secret: secret,
                        tcp_url: 'test.com',
                        base_url: 'base.url.com')
    end

    let(:params) do
      {
        lti_message_type: 'basic-lti-launch-request',
        lti_version: 'LTI-2p0',
        resource_link_id: '0f5c211411bd78638d3f024f771f7ae9d020a352',
        user_id: '14e94b100f487430355fd888cf3d298ae474188b'
      }
    end

    let(:oauth_attributes) do
      {
        consumer_key: tool_proxy.guid,
        consumer_secret: tool_proxy.shared_secret,
        callback: 'about:blank'
      }
    end

    let(:signed_params) do
      header = SimpleOAuth::Header.new(:post, 'http://example.org/basic-launch', params, oauth_attributes)
      header.signed_attributes.merge(params)
    end

    it 'accepts a basic lti launch' do
      post '/basic-launch', signed_params
      expect(last_response).to be_ok
    end

    it 'returns 404 if tool proxy not found' do
      tool_proxy.delete
      post '/basic-launch', signed_params
      expect(last_response).to be_not_found
    end

    it 'returns 401 if OAuth 1 signature is invalid' do
      signed_params[:oauth_signature] = 'bad signature'
      post '/basic-launch', signed_params
      expect(last_response).to be_unauthorized
    end

    it 'only accepts the nonce once' do
      2.times { post '/basic-launch', signed_params }
      expect(last_response).to be_unauthorized
    end

    it 'only accepts the timestamp if it is less than 5 minutes old' do
      oauth_attributes[:timestamp] = 6.minutes.ago.to_i
      post '/basic-launch', signed_params
      expect(last_response).to be_unauthorized
    end

    it 'only accepts the timestamp if it is less than 1 minutes in the future' do
      oauth_attributes[:timestamp] = 2.minutes.from_now
      post '/basic-launch', signed_params
      expect(last_response).to be_unauthorized
    end
  end
end
