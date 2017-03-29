require_relative 'spec_helper'

RSpec.shared_context 'lti_spec_helper', shared_context: :metadata do
  include_context 'spec_helper'

  let(:tool_proxy_url) { 'http://canvas.docker:80/api/lti/courses/2/tool_proxy' }
  let(:tool_consumer_profile) do
    {
      'lti_version' => 'LTI-2p0',
      'guid' => '339b6700-e4cb-47c5-a54f-3ee0064921a9',
      'capability_offered' => [
        'User.id',
        'Security.splitSecret'
      ],
      'service_offered' => [
        {
          'endpoint' => tool_proxy_url,
          'format' => [
            'application/vnd.ims.lti.v2.toolproxy+json'
          ],
          'action' => [
            'POST'
          ],
          '@id' => 'http://canvas.docker/api/lti/courses/2/tool_consumer_profile/339b6700-e4cb-47c5-a54f-3ee0064921a9#ToolProxy.collection',
          '@type' => 'RestService'
        }
      ],
      'security_profile' => [
        {
          'security_profile_name' => 'lti_oauth_hash_message_security',
          'digest_algorithm' => ['HMAC-SHA1']
        },
        {
          'security_profile_name' => 'oauth2_access_token_ws_security',
          'digest_algorithm' => ['HS256']
        }
      ],
      '@id' => 'http://canvas.docker/api/lti/courses/2/tool_consumer_profile/339b6700-e4cb-47c5-a54f-3ee0064921a9',
      '@type' => 'ToolConsumerProfile',
      '@context' => [
        'http://purl.imsglobal.org/ctx/lti/v2/ToolConsumerProfile'
      ]
    }
  end

  let(:tool_proxy_guid) { 'bdecc237-fecb-4f1a-a455-109cbd618406' }
  let(:tc_half_shared_secret) do
    'ed6d2853c5f39633a3ac6dde202b1d100ec7a40b3ddd7827d9bb1f1433a2d31bd81\
    186cc5f4d533208ff51d07bd0f54b96b81422171028e75aeb07e5cca241aa'
  end
  let(:tool_proxy_response_body) do
    {
      '@context' => 'http://purl.imsglobal.org/ctx/lti/v2/ToolProxyId',
      '@type' => 'ToolProxy',
      '@id' => nil,
      'tool_proxy_guid' => tool_proxy_guid,
      'tc_half_shared_secret' => tc_half_shared_secret
    }
  end

  let(:access_token) { '2YotnFZFEjr1zCsicMWpAA' }

  let(:authorization_server_response) do
    double('authorization_server_response', parsed_response:
      {
        'access_token' => access_token,
        'token_type' => 'Bearer',
        'expires_in' => 3600
      })
  end

  let(:tool_proxy_response) do
    double('tool_proxy_response', body: tool_proxy_response_body.to_json, code: 201)
  end
  let(:bad_tool_proxy_response) do
    double('bad_tool_proxy_response', body: { error: 'some error' }.to_json, code: 400)
  end

  let(:launch_url) { 'http://localhost:9292/basic-launch' }
  let(:secret) do
    'ab99f9cce30bc16a0294e8aafb2553eb446569f21414e2f0c52a20326c7e3b7486af4d795\
    6971da713324fde46a9ba48737193f04976abca36ba9002276b5051c0dfae7c0297f6dc514\
    a05c235fb4dc8d5b0534d51ef0d1dd1ae2c66c42c026a6b2d7c961d87ad2815d01c6264bd7f\
    6acac1fde2cf796aade7c42a7ef02acdb8'
  end
  let(:params) do
    {
      oauth_callback: 'about:blank',
      oauth_consumer_key: tool_proxy_guid,
      oauth_nonce: 'e0d8cb253086f66a864c53d66b53a6d5',
      oauth_signature_method: 'HMAC-SHA1',
      oauth_timestamp: '1489170331',
      oauth_version: '1.0',
      oauth_signature: '0icuM35sNAD6OTsR2f8c8Es/ECU=',
      lti_message_type: 'basic-lti-launch-request',
      lti_version: 'LTI-2p0',
      resource_link_id: '0f5c211411bd78638d3f024f771f7ae9d020a352',
      user_id: '14e94b100f487430355fd888cf3d298ae474188b'
    }.with_indifferent_access
  end
end
