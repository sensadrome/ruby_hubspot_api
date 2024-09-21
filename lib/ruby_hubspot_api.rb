# frozen_string_literal: true

require 'httparty'

# Load the main Hubspot module, version and configuration
require_relative 'hubspot'
require_relative 'hubspot/version'
require_relative 'hubspot/config'

# define the exception classes, then load the main API client
require_relative 'hubspot/exceptions'
require_relative 'hubspot/api_client'

# load base class then modules
require_relative 'hubspot/resource'
