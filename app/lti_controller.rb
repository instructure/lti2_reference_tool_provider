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
    # 1. Fetch tool consumer profile (See section 6.1.2)
    tcp_url = URI.parse(params[:tc_profile_url])
    tcp = JSON.parse(HTTParty.get(tcp_url))

    # 2. Register the tool proxy with the tool consumer (See section 6.1.3)
    #    - Find the ToolProxy.collection service endpoint from
    #      the TCP (See section 10.1)
    tp_endpoint = tool_proxy_service_endpoint(tcp)

    #    - Construct the signed tool proxy request and send (See section 6.1.3)
    tool_proxy = ToolProxy.new(tcp_url: tcp_url,
                               shared_secret: SecureRandom.hex(128),
                               base_url:  request.base_url)
    signed_request = tool_proxy_signed_post(tool_proxy, tp_endpoint)
    tp_response = HTTParty.post(tp_endpoint, signed_request)

    # 3. Make the tool proxy available (See section 6.1.4)
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

  # tool_proxy_signed_post
  #
  # Creates a signed post request to register the
  # tool proxy with the tool consumer (See section 6.1.3).
  def tool_proxy_signed_post(tool_proxy, endpoint)
    # Options for authorzation header (See https://oauth.net/core/1.0/ Section 5.4.1)
    options = {
      consumer_secret: params[:reg_password],
      consumer_key: params[:reg_key],
      body_hash: Digest::SHA1.base64digest(tool_proxy.to_json),
      callback: 'about:blank'
    }

    # Assemble the authorization header
    header = SimpleOAuth::Header.new(
      :post,
      endpoint,
      {},
      options
    )

    # Assemble and return the request
    {
      body: tool_proxy.to_json,
      headers: {
        'Content-Type' => 'application/vnd.ims.lti.v2.toolproxy+json',
        'Authorization' => header.to_s
      }
    }
  end
end
