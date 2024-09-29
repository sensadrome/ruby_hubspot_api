# frozen_string_literal: true

require 'httparty'
require 'logger'

# Load the main Hubspot module, version and configuration
require_relative 'hubspot'
require_relative 'hubspot/version'
require_relative 'hubspot/config'

# define the exception classes, then load the main API client
require_relative 'hubspot/exceptions'
require_relative 'hubspot/api_client'

# load base class then modules
require_relative 'hubspot/resource'
require_relative 'hubspot/property'
require_relative 'hubspot/contact'
require_relative 'hubspot/company'
require_relative 'hubspot/user'

# Load other components
require_relative 'hubspot/batch'
require_relative 'hubspot/paged_collection'

require_relative 'support/patches'
