require_relative 'spec_helper'

RSpec.shared_context 'lti_spec_helper', shared_context: :metadata do
  include_context 'spec_helper'

  let(:tool_consumer_profile) do
    {
       'lti_version' => 'LTI-2p0',
       'guid' => '339b6700-e4cb-47c5-a54f-3ee0064921a9',
       'capability_offered' => [
          'User.id',
       ],
       'service_offered' => [
        {
          'endpoint' => 'http://canvas.docker:80/api/lti/courses/2/tool_proxy',
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
       '@id' => 'http://canvas.docker/api/lti/courses/2/tool_consumer_profile/339b6700-e4cb-47c5-a54f-3ee0064921a9',
       '@type' => 'ToolConsumerProfile',
       '@context' => [
          'http://purl.imsglobal.org/ctx/lti/v2/ToolConsumerProfile'
       ]
    }
  end

  let(:tool_proxy_guid){ 'bdecc237-fecb-4f1a-a455-109cbd618406' }
  let(:tc_half_shared_secret){ 'tool-consumer-half-split-secret' }
  let(:tool_proxy_response_body) do
    {
      '@context' => 'http://purl.imsglobal.org/ctx/lti/v2/ToolProxyId',
      '@type' => 'ToolProxy',
      '@id' => nil,
      'tool_proxy_guid' => tool_proxy_guid,
      'tc_half_shared_secret' => tc_half_shared_secret
    }
  end

  let(:tool_proxy_response){ double(body: tool_proxy_response_body.to_json, code: 201) }
  let(:bad_tool_proxy_response){ double(body: {error: 'some error'}.to_json, code: 400) }

end
