class MessageAuthenticator

  attr_reader :launch_url, :params, :message, :simple_oauth_header, :signature, :consumer_key

  def initialize(launch_url:, params:, secret:)
    @launch_url = launch_url
    @params = params
    @consumer_key = params['oauth_consumer_key']
    @signature = params['oauth_signature']
    @secret = secret
  end

  # valid_signature?
  #
  # Checks if the signature is valid
  def valid_signature?
    # Check the OAuth 1 Signature
    # NOTE: a check for duplicate nonces should also be done here.
    header.valid?(signature: signature)
  end

  # header
  #
  # Assembles the authorization header using
  # the provided secret
  def header
    SimpleOAuth::Header.new(
      :post, launch_url,
      params,
      {
        consumer_key: consumer_key,
        consumer_secret: @secret,
        callback: 'about:blank'
      }
    )
  end

end
