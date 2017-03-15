require 'sinatra/activerecord'

class ToolProxy < ActiveRecord::Base
  validates :guid, :shared_secret, :tcp_url, :base_url, :tp_half_shared_secret, presence: true

  TOOL_PROXY_FORMAT = 'application/vnd.ims.lti.v2.toolproxy+json'.freeze

  # to_json
  #
  # Returns a tool proxy as JSON ready to be sent in the
  # tool proxy post request to the tool provider (See section 6.1.3)
  def to_json
    self.as_json.to_json
  end

  # to_json
  #
  # Returns a tool proxy as a hash
  def as_json
    tool_proxy_hash = super()
    tool_proxy_hash.merge({
      '@context' => 'http://purl.imsglobal.org/ctx/lti/v2/ToolProxy',
      lti_version: 'LTI-2p0', # LTI-2p0 should be used for all LTI 2.x tools
      tool_consumer_profile: tcp_url,
      tool_profile: tool_profile,
      security_contract: security_contract,
      enabled_capability: ['Security.splitSecret'] # (Section 5.3)
    })
  end

  private

  # tool_profile
  #
  # Returns a tool profile for use in the tool proxy (See section 5.4).
  def tool_profile
    {
      "lti_version" => "LTI-2p0", "product_instance" => {
        "guid" => "be42ae52-23fe-48f5-a783-40ecc7ef6d5c",
        "product_info" => product_info
      },
      "base_url_choice" => base_url_choice,
      "resource_handler" => resource_handler
    }
  end


  # security_contract
  #
  # Returns the security contract for use in the tool proxy (See section 5.6)
  def security_contract
    {
      tp_half_shared_secret: tp_half_shared_secret
    }
  end

  # product_info
  #
  # Returns the product info to be used in the tool profile (See section 5.1.2)
  def product_info
    {
      "product_name" => {
        "default_value" => "lti2_reference_tool_provider"
      },
      "product_version" => "1.0", "description" => {
        "default_value" => "LTI 2.1 tool provider reference implementation"
      },
      "product_family" => {
        "code" => "lti2_reference_tool_provider",
        "vendor" => {
          "code" => "Instructure.com",
          "vendor_name" => {
            "default_value" => "Instructure"
          },
          "description" => {
            "default_value" => "Canvas Learning Management System"
          }
        }
      }
    }
  end

  # base_url_choice
  #
  # Returns the product info to be used in the tool profile (See section 5.4.5)
  def base_url_choice
    [{
      "default_base_url" => base_url,
      "selector" => {
        "applies_to" => ["MessageHandler"]
      }
    }]
  end

  # resource_handler
  #
  # Returns the resource handler to be used in the tool profile (See section 5.4.2)
  def resource_handler
    [{
      "resource_type" => {
        "code" => "lti2_reference_tool_provider"
      },
      "resource_name" => {
        "default_value" => "lti2_reference_tool_provider"
      },
      "message" => [{
        "message_type" => "basic-lti-launch-request", "path" => "/basic-launch",
        "enabled_capability" => []
      }]
    }]
  end
end
