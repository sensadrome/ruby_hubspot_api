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

# load base class then models
require_relative 'hubspot/resource'
require_relative 'hubspot/property'

# load CRM models
require_relative 'hubspot/contact'
require_relative 'hubspot/company'
require_relative 'hubspot/user'

# load marketing models
require_relative 'hubspot/form'

# Load other components
require_relative 'hubspot/batch'
require_relative 'hubspot/paged_collection'

require_relative 'support/patches'
