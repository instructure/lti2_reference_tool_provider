class MessageAuthenticator

  attr_reader :launch_url, :params, :message, :simple_oauth_header, :signature, :consumer_key

  def initialize(launch_url:, params:, secret:)
    @launch_url = launch_url
    @params = params
    @options, @parsed_params = parse_params(params)
    @consumer_key = @options[:consumer_key]
    @signature = @parsed_params.delete(:oauth_signature)
    @secret = secret
  end

  # valid_signature?
  #
  # Checks if the signature is valid
  def valid_signature?
    header.valid?(signature: signature)
  end

  # header
  #
  # Assembles the authorization header using
  # the provided secret to verify signature
  def header
    simple_oauth_header = SimpleOAuth::Header.new(
      :post, launch_url,
      @parsed_params,
      @options.merge(
        {
          consumer_key: consumer_key,
          consumer_secret: @secret,
          callback: 'about:blank'
        }
      )
    )
  end

  private

  def parse_params(params)
    params.inject([{}, {}]) do |array, (k, v)|
      attr = k.to_s.sub('oauth_', '').to_sym
      if SimpleOAuth::Header::ATTRIBUTE_KEYS.include?(attr)
        array[0][attr] = v
      else
        array[1][k.to_sym] = v
      end
      array
    end
  end

end
