require 'securerandom'

class LtiController < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  set :views, ->{ File.join(root, '/views') }
  set :protection, except: :frame_options

  # register
  #
  # Handles incoming tool proxy registration requests, fetches
  # the tool consumer profile from the tool consumer, and
  # creates a tool proxy in the tool consumer. See section
  # 4.5 of the LTI 2.1 spec
  post '/register' do

    # 1. Get a JWT access token for use in retrieving the tool consumer profile
    # and registering a tool proxy
    token = jwt_access_token(url: 'http://canvas.docker/api/lti/authorize', # eventually this will be sent in the registration message
                             sub: '10000000000003', # Developer key global id
                             secret: 'BXfJR44Ng3czXFt02UZwrzMSFn1GcT8KjY6wUL0RJSVIv271eCoa4KLzwciSg4fD', # Developer key api key. Don't store this here ;)
                             code: params[:reg_key])

    # 2. Fetch tool consumer profile (See section 6.1.2). Use the JWT access
    # token to fetch the TCP associated with the developer key.
    tcp_url = URI.parse(params[:tc_profile_url])
    tcp = JSON.parse(HTTParty.get(tcp_url, tcp_request(token, '10000000000003')))

    # 3. Register the tool proxy with the tool consumer (See section 6.1.3)
    #    - Find the ToolProxy.collection service endpoint from
    #      the TCP (See section 10.1)
    tp_endpoint = tool_proxy_service_endpoint(tcp)

    #    - Construct the signed tool proxy request and send (See section 6.1.3)
    tool_proxy = ToolProxy.new(tcp_url: tcp_url,
                               shared_secret: SecureRandom.hex(128),
                               base_url:  request.base_url)
    authorized_request = tool_proxy_request(tool_proxy, token)
    tp_response = HTTParty.post(tp_endpoint, authorized_request)

    # 4. Make the tool proxy available (See section 6.1.4)
    #    - Check for success and redirect to the tool consumer with proper
    #      query parameters (See section 6.1.4 and 4.4).
    redirect_url = "#{params[:launch_presentation_return_url]}?"
    if tp_response.code == 201

      #  - Get the tool proxy guid from the tool proxy create response
      tool_proxy_guid = JSON.parse(tp_response.body)['tool_proxy_guid']

      #  - Persist the tool proxy
      tool_proxy.update_attributes(guid: tool_proxy_guid)

      # - Setup the redirect query parameters
      redirect_url << "tool_proxy_guid=#{tool_proxy_guid}&status=success"
    else
      redirect_url << "status=failure"
    end
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

  # tool_proxy_request
  #
  # Creates a tool proxy create request.
  # Should use the same JWT access access token used
  # to fetch the custom tool consumer profile
  def tool_proxy_request(tool_proxy, access_token)
    # Assemble and return the request
    {
      body: tool_proxy.to_json,
      headers: {
        'Content-Type' => 'application/vnd.ims.lti.v2.toolproxy+json',
        'Authorization' => "Bearer #{access_token}"
      }
    }
  end

  # tcp_request
  #
  # Requests a custom tool consumer profile associated
  # with the specified developer key. See header comments
  # of #jwt_access_token for information on using the
  # access_token
  def tcp_request(access_token, developer_key_id)
    # Set the 'consumer_key' query parameter to the ID of the developer key
    query = {
      consumer_key: developer_key_id
    }

    {
      query: query,
      headers: {
        'Authorization' => "Bearer #{access_token}"
      }
    }
  end

  # jwt_access_token
  #
  # Retrieves a JWT access token from the tool consumer. This
  # access token can be used to fetch a custom tool consumer profile
  # with restricted capabilities and services.
  #
  # This access token can also be used to register a tool proxy and make
  # requests to LTI2 endpoints.
  #
  # When requesting a JWT access token for use in fetching a custom TCP
  # and creating a tool proxy the 'sub' should be set to the global ID
  # of the developer key associated with the custom TCP. The 'secret' should
  # be the develoepr key api key, and the 'code' should be the 'reg_key' param
  # sent by the tool consumer in the registration request.
  #
  # When requesting a JWT access token for use in LTI2 API endpoints the
  # 'sub' should be the tool proxy guid, the 'secret' should be the tool's
  # shared secret, and the 'code' should be excluded.
  def jwt_access_token(url:, sub:, secret:, code: nil)
    assertion = JSON::JWT.new({
      sub: sub,
      aud: url,
      exp: 1.minute.from_now,
      iat: Time.now.to_i,
      jti: SecureRandom.uuid
    })
    assertion = assertion.sign(secret, :HS256).to_s

    request = {
      body: {
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: assertion
      }
    }

    # If using a developer key as the subject
    if code.present?
      request = {
        body: {
          grant_type: 'authorization_code',
          code: code,
          assertion: assertion
        }
      }
    end

    response = HTTParty.post(url, request)
    response.parsed_response['access_token']
  end

end
