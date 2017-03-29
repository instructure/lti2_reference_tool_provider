require 'securerandom'
# LtiController
#
# Handles registration and basic LTI launches
class LtiController < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  set :views, -> { File.join(root, '/views') }
  set :protection, except: :frame_options

  # register
  #
  # Handles incoming tool proxy registration requests, fetches
  # the tool consumer profile from the tool consumer, and
  # creates a tool proxy in the tool consumer. See section
  # 4.5 of the LTI 2.1 spec
  post '/register' do
    # 1. Fetch tool consumer profile (See section 6.1.2)
    tcp_url = URI.parse(params[:tc_profile_url])
    tcp = JSON.parse(HTTParty.get(tcp_url))

    # Redirect to Tool Consumer with 'status=failure' if the tool
    # consumer does not support all required capabilities (i.e. split
    # secret, or required security profiles).
    #
    # Alternatively fallback on registering with a traditional shared secret
    # the Tool Consumer does not support using.
    registration_failure_redirect unless required_capabilities?(tcp) && support_oauth2_ws?(tcp)

    # 2. Register the tool proxy with the tool consumer (See section 6.1.3)
    #    - Find the ToolProxy.collection service endpoint from
    #      the TCP (See section 10.1)
    tp_endpoint = tool_proxy_service_endpoint(tcp)

    tool_proxy = ToolProxy.new(tcp_url: tcp_url,
                               base_url:  request.base_url)

    #    - Get an OAuth2 token for making API calls
    #      This involves creating a JWT that we will send to the tool consumer
    #      authorization server in exchange for an access token
    #      see section 3.2 of the LTI security Document
    access_token = access_token_request(
      aud: URI.parse(params['oauth2_access_token_url']),
      sub: params[:reg_key],
      secret: params[:reg_password]
    )

    #    - Construct the tool proxy create request

    tp_response = tool_proxy_request(tp_endpoint, access_token, tool_proxy)

    # 3. Make the tool proxy available (See section 6.1.4)
    #    - Check for success and redirect to the tool consumer with proper
    #      query parameters (See section 6.1.4 and 4.4).
    registration_failure_redirect unless tp_response.code == 201

    #    - Get the tool proxy guid from the tool proxy create response
    tool_proxy_guid = JSON.parse(tp_response.body)['tool_proxy_guid']

    #    - Get the tool consumer half of the shared split secret and construct
    #      the complete shared secret (See section 5.6).
    tc_half_shared_secret = JSON.parse(tp_response.body)['tc_half_shared_secret']
    shared_secret = tc_half_shared_secret + tool_proxy.tp_half_shared_secret

    #    - Persist the tool proxy
    tool_proxy.update_attributes(guid: tool_proxy_guid,
                                 shared_secret: shared_secret)

    # - Setup the redirect query parameters
    redirect_url = "#{params[:launch_presentation_return_url]}?tool_proxy_guid=#{tool_proxy_guid}&status=success"
    redirect redirect_url
  end

  # basic-launch
  #
  # Handles incoming basic LTI launch requests. See section 4.4
  # of the LTI 2.1 spec.
  #
  # Renders 404 if tool proxy is not found with the specified guid
  #
  # Renders 401 if the request's oauth signature is invalid
  post '/basic-launch' do
    # Lookup the tool proxy by guid. Return 404 if the tool proxy is not found.
    tool_proxy = ToolProxy.find_by(guid: params['oauth_consumer_key']) || halt(404)

    # Retrieve the tool proxy's shared secret
    shared_secret = tool_proxy.shared_secret

    # Assemble the header to validate the OAuth1 signature
    options = {
      consumer_key: params['oauth_consumer_key'],
      consumer_secret: shared_secret,
      callback: 'about:blank'
    }
    launch_url = "#{request.base_url}#{request.path}"
    header = SimpleOAuth::Header.new(:post, launch_url, params, options)

    # Render unauthorized if the signature is invalid
    # NOTE: A check should also be done to detect and reject duplicate
    # nonces.
    halt(401) unless header.valid?

    # Render
    erb :basic_launch
  end

  private

  # support_oauth2_ws?
  #
  # checks that the tool consumer supports the oauth2 ws profile
  def support_oauth2_ws?(tool_profile)
    profile = tool_profile['security_profile'].find do |p|
      p['security_profile_name'] == 'oauth2_access_token_ws_security'
    end
    profile && profile['digest_algorithm'].include?('HS256')
  end

  # tool_proxy_service_endpoint
  #
  # Finds the tool proxy collection service.
  #
  # Search for the RestService in the TCP that supports the
  # "application/vnd.ims.lti.v2.toolproxy+json" format (See section 10.1)
  def tool_proxy_service_endpoint(tcp)
    tp_services = tcp['service_offered'].find do |s|
      s['format'] == [ToolProxy::TOOL_PROXY_FORMAT]
    end

    # Retrieve and return the endpoint of the ToolProxy.collection service
    URI.parse(tp_services['endpoint']) unless tp_services.blank?
  end

  # required_capabilities??
  #
  # Checks if the tool consumer supports required capabilities
  # i.e. split secret (See section 5.6).
  def required_capabilities?(tcp)
    (ToolProxy::ENABLED_CAPABILITY - tcp['capability_offered']).blank?
  end

  def registration_failure_redirect
    redirect_url = "#{params[:launch_presentation_return_url]}?status=failure"
    redirect redirect_url
  end

  def tool_proxy_request(url, access_token, tool_proxy)
    HTTParty.post(
      url,
      headers: {
        'Content-Type' => 'application/vnd.ims.lti.v2.toolproxy+json',
        'Authorization' => "Bearer #{access_token}"
      },
      body: tool_proxy.to_json
    )
  end

  # access_token
  #
  # Construct the JWT request used to get an access token from the Tool Consumer
  # This access token can be used to register a tool proxy
  # See section 3.2 of the LTI security document
  #
  # When requesting a JWT access token for use in creating a tool proxy
  # the 'iss' should be set to the tools domain
  # the 'sub' should be set to the reg_key parameter.
  # the 'aud' should be set to the authorization server endpoint
  # the 'iat' is the timestamp of when the JWT is created
  # the 'exp' is the timestamp for when the JWT should be considered expired
  # the 'jti' is a unique value to identify the JWT, it may be used as a nonce
  # sent by the tool consumer in the registration request.
  #
  # When requesting a JWT access token for use in LTI2 API endpoints the
  # 'sub' should be the tool proxy guid, the 'secret' should be the tool's
  # shared secret, and the 'code' should be excluded.
  #
  # It should also be noted that the response from the authorization server
  # includes 3 pieces of data:
  # 'access_token': the token used to make api calls
  # 'token_type': the type of token, currently the only supported type is 'Bearer'
  # 'expires_in': when the token expires, we are only making one call with the token,
  # so we aren't concerned with it's expiration. When using it for multiple api
  # calls over a period of time, you should track the expiration.
  def access_token_request(aud:, sub:, secret:)
    assertion = JSON::JWT.new(
      iss: request.host,
      sub: sub,
      aud: aud.to_s,
      iat: Time.now.to_i,
      exp: 1.minute.from_now,
      jti: SecureRandom.uuid
    )
    assertion = assertion.sign(secret, :HS256).to_s
    request = {
      # The body of the HTML POST includes two parameters: the 'grant_body', and the 'assertion'
      # the grant_type must be equal to the string 'urn:ietf:params:oauth:grant-type:jwt-bearer'
      # the assertion is the the JWT signed with the reg_password
      body: {
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: assertion
      }
    }
    response = HTTParty.post(aud, request)
    response.parsed_response['access_token']
  end
end
