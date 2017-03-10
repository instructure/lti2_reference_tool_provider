require_relative 'lti_spec_helper'

describe MessageAuthenticator do
  include_context 'lti_spec_helper'

  def app
    MessageAuthenticator
  end

  let(:launch_url){'http://localhost:9292/basic-launch'}
  let(:secret){ 'ab99f9cce30bc16a0294e8aafb2553eb446569f21414e2f0c52a20326c7e3b7486af4d7956971da713324fde46a9ba48737193f04976abca36ba9002276b5051c0dfae7c0297f6dc514a05c235fb4dc8d5b0534d51ef0d1dd1ae2c66c42c026a6b2d7c961d87ad2815d01c6264bd7f6acac1fde2cf796aade7c42a7ef02acdb8' }
  let(:params) do
    {
      oauth_callback: "about:blank",
      oauth_consumer_key: "4b1f5211-03ec-4769-b0eb-3326486636ed",
      oauth_nonce: "e0d8cb253086f66a864c53d66b53a6d5",
      oauth_signature_method: "HMAC-SHA1",
      oauth_timestamp: "1489170331",
      oauth_version: "1.0",
      oauth_signature: "0icuM35sNAD6OTsR2f8c8Es/ECU=",
      lti_message_type: "basic-lti-launch-request",
      lti_version: "LTI-2p0",
      resource_link_id: "0f5c211411bd78638d3f024f771f7ae9d020a352",
      user_id: "14e94b100f487430355fd888cf3d298ae474188b"
    }
  end
  let(:message_authenticator) { MessageAuthenticator.new(launch_url: launch_url, secret: secret, params: params) }

  describe 'valid_signature?' do
    it 'returns true for valid signatures' do
      expect(message_authenticator.valid_signature?).to eq true
    end

    it 'returns false for invalid signatures' do
      params[:oauth_consumer_key] = '4b1f5211-03ec-4769-b0eb-3326486636e'
      ma = MessageAuthenticator.new(launch_url: launch_url, secret: secret, params: params)
      expect(ma.valid_signature?).to eq false
    end
  end

  describe 'header' do
    let(:header_options) { message_authenticator.header.options }

    it 'does not include non-oauth headers' do
      expect(header_options.keys).not_to include(:resource_link_id)
    end

    it 'does include oauth headers' do
      expected_keys = params.keys.select{ |p| p.to_s.include?('oauth_')}.map{ |s| s.to_s.split('oauth_').last }
      expect(header_options.keys.map(&:to_s) - expected_keys).to eq ["consumer_secret"]
    end
  end

end
