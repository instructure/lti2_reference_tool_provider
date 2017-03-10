require 'sinatra/activerecord'

class ToolProxy < ActiveRecord::Base
  # to_json
  #
  # Returns a tool proxy JSON ready to be sent in the
  # tool proxy post request to the tool provider (See section 6.1.3)
  def to_json(request)
    {
      '@context' => 'http://purl.imsglobal.org/ctx/lti/v2/ToolProxy',
      lti_version: 'LTI-2p0', # LTI-2p0 should be used for all LTI 2.x tools
      tool_consumer_profile: tcp_url,
      tool_profile: tool_profile(request),
      security_contract: security_contract,
      enabled_capability: [] # (Section 5.3)
    }.to_json
  end

  private

  # tool_profile
  #
  # Returns a tool profile for use in the tool proxy (See section 5.4).
  def tool_profile(request)
    profile = JSON.parse(File.read('config/tool_profile.json'))
    profile['base_url_choice'].first['default_base_url'] = request.base_url
    profile
  end


  # security_contract
  #
  # Returns the security contract for use in the tool proxy (See section 5.6)
  def security_contract
    {
      shared_secret: shared_secret
    }
  end
end
