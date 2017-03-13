require_relative 'lti_spec_helper'

describe MessageAuthenticator do
  include_context 'lti_spec_helper'

  def app
    MessageAuthenticator
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
