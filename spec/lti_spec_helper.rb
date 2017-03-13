require_relative 'spec_helper'

RSpec.shared_context "lti_spec_helper", shared_context: :metadata do
  include_context 'spec_helper'

  let(:tool_consumer_profile) do
    {
       "lti_version" => "LTI-2p0",
       "guid" => "339b6700-e4cb-47c5-a54f-3ee0064921a9",
       "capability_offered" => [
          "User.id",
       ],
       "service_offered" => [
        {
          "endpoint" => "http://canvas.docker:80/api/lti/courses/2/tool_proxy",
             "format" => [
                "application/vnd.ims.lti.v2.toolproxy+json"
             ],
             "action" => [
                "POST"
             ],
             "@id" => "http://canvas.docker/api/lti/courses/2/tool_consumer_profile/339b6700-e4cb-47c5-a54f-3ee0064921a9#ToolProxy.collection",
             "@type" => "RestService"
          }
       ],
       "@id" => "http://canvas.docker/api/lti/courses/2/tool_consumer_profile/339b6700-e4cb-47c5-a54f-3ee0064921a9",
       "@type" => "ToolConsumerProfile",
       "@context" => [
          "http://purl.imsglobal.org/ctx/lti/v2/ToolConsumerProfile"
       ]
    }
  end

  let(:tool_proxy_guid) { '4b1f5211-03ec-4769-b0eb-3326486636ed' }

  let(:tool_proxy_response_body) do
    {
      "@context" => "http://purl.imsglobal.org/ctx/lti/v2/ToolProxyId",
      "@type" => "ToolProxy",
      "@id" => nil,
      "tool_proxy_guid" => tool_proxy_guid
    }
  end

  let(:tool_proxy_response){ double(body: tool_proxy_response_body.to_json, code: 201) }
  let(:bad_tool_proxy_response){ double(body: {error: 'some error'}.to_json, code: 400) }

  let(:launch_url){'http://localhost:9292/basic-launch'}
  let(:secret){ 'ab99f9cce30bc16a0294e8aafb2553eb446569f21414e2f0c52a20326c7e3b7486af4d7956971da713324fde46a9ba48737193f04976abca36ba9002276b5051c0dfae7c0297f6dc514a05c235fb4dc8d5b0534d51ef0d1dd1ae2c66c42c026a6b2d7c961d87ad2815d01c6264bd7f6acac1fde2cf796aade7c42a7ef02acdb8' }
  let(:params) do
    {
      oauth_callback: "about:blank",
      oauth_consumer_key: tool_proxy_guid,
      oauth_nonce: "e0d8cb253086f66a864c53d66b53a6d5",
      oauth_signature_method: "HMAC-SHA1",
      oauth_timestamp: "1489170331",
      oauth_version: "1.0",
      oauth_signature: "0icuM35sNAD6OTsR2f8c8Es/ECU=",
      lti_message_type: "basic-lti-launch-request",
      lti_version: "LTI-2p0",
      resource_link_id: "0f5c211411bd78638d3f024f771f7ae9d020a352",
      user_id: "14e94b100f487430355fd888cf3d298ae474188b"
    }.with_indifferent_access
  end
end
