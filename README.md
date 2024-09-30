# Ruby HubSpot API Gem

[![codecov](https://codecov.io/gh/sensadrome/ruby_hubspot_api/branch/main/graph/badge.svg)](https://codecov.io/gh/sensadrome/ruby_hubspot_api) [![Codacy Badge](https://app.codacy.com/project/badge/Grade/504ca01245ee4928b6ed0b13801259e7)](https://app.codacy.com/gh/sensadrome/ruby_hubspot_api/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

This gem was largely inspired by [hubspot-api-ruby](https://github.com/captaincontrat/hubspot-api-ruby) which, in turn, was inspired by the [hubspot-ruby](https://github.com/HubspotCommunity/hubspot-ruby) community gem. I wanted to use version 3 of the api and simplify some parts of the interface

The Ruby HubSpot API gem is a starting point for building an ORM-like interface to HubSpot's API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby_hubspot_api'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install ruby_hubspot_api
```

## Configuration

To authenticate API requests, you need a HubSpot access token. First you will need to add a [private app in hubspot](https://developers.hubspot.com/docs/api/private-apps) When that is setup you can go to the "Auth" tab of your private app page and grab the access token from there

You can configure the gem by adding this code to your initializer (for Rails) or to your startup configuration (in any other environment):

##### Minimum configuration

```ruby
Hubspot.configure do |config|
  config.access_token = 'your_access_token'
end
```

##### Full possible configuration

```ruby
Hubspot.configure do |config|
  config.access_token = 'your_access_token'
  config.portal_id = 'your_portal_id'
  config.client_secret = 'your_client_secret'
  config.logger = Rails.logger
  config.log_level = 'info' # debug,info,warn,error,fatal
  config.timeout = 10 # seconds to timeout all api requests
  config.open_timeout = 5 # open_timeout seconds
  config.read_timeout = 5 # read_timeout seconds
  config.write_timeout = 5 # swrite_timeout econds (ruby >= 2.6)
end
```

This configuration ensures that your API requests are authenticated using your HubSpot access token.

## Working with Resources

This gem allows you to interact with Hubspot resources such as contacts and companies. You can perform operations on individual resources (e.g., creating or updating records) as well as on collections (e.g., listing or searching).

__please note__

> In the Hubspot API contacts, companies etc are referred to as "Objects" (e.g. CRM > Objects > Contacts) so when we use the word "Object" (with a capital O) we will be referring to an object in Hubspot

> In this gem we use the term Resource so as not to accidentally overload Object! When we use the term "Resource" we should be referring to the ruby ORM base class and when we say "resource" we should be referring to an instance of this class (or a class that inherits it)

### Hubspot::Resource class

This is the base ORM class for all Hubspot CRM objects. You should not operate on this class but with the following classes each of which inherits from Hubspot::Resource

```ruby
Hubspot::Contact  # crm > contacts
Hubspot::Company  # crm > companies
Hubspot::User     # hubspot users (also referred to as 'owners')
Hubspot::Owner    # alias of Hubspot::User if you prefer to use it
```
 
however you can [add custom objects of your own](#user-content-custom-resources) based on your own custom defined Objects in Hubspot

### Creating and Saving an Object

Create and instance of the resource passing a hash of properties. Calling `save` on the instance will persist the object to the HubSpot API, as well as set the id property (which you can then store in your own database for example)

Example:

```ruby
new_contact = Hubspot::Contact.new(firstname: 'John', lastname: 'Doe', email: 'john.doe@example.com')

# Save the contact to HubSpot
new_contact.save

# After saving, the contact will be assigned an ID by the API
puts "New contact ID: #{new_contact.id}"
```

### Retreiving an Object

If you know the id of the object you can fetch it from the api using the find method

```ruby
contact = Hubspot::Contact.find(1)
puts "Contact: #{contact.firstname} #{contact.lastname}"
```

You can also retrieve a single object by using the `find_by` method. Simply specify the property and the value you want to search on:

```ruby
# find by email
contact = Hubspot::Contact.find_by('email', 'john.doe@example.org')
puts "Contact: #{contact.firstname} #{contact.lastname}"

#find by internal id (custom field)
contact = Hubspot::Contact.find_by('member_id', 123)
puts "Contact: #{contact.firstname} #{contact.lastname}"
```

### Updating an Existing Object

To update an existing object, you can either modify the object and call `save`, or use the `update` method specifying the properties you want to update. You can test whether or not the object will need to upload changes to the api by using the changes? method

Example using `save`:

```ruby
contact = Hubspot::Contact.find(1)
contact.changes? # false

contact.lastname = 'DoeUpdated'
contact.changes? # true

# save the updates to Hubspot
contact.save # true
contact.changes? # false
```

Example using `update`:

```ruby
contact = Hubspot::Contact.find(1)
# save the updates to Hubspot
contact.update(lastname: 'DoeUpdated') # true
```

If you are able to construct an Object with data stored locally you can save the inital `find` api call, but you will need to construct the persisted object specifying the id and a properties hash (as if it came from the api!)

Example:

```ruby
local_contact = Contact.find(contact_id)

hubspot_properties = {
  firstname: local_contact.first_name,
  lastname: local_contact.last_name,
  email: local_contact.email,
  # ... more properties...
}

hubspot_contact = Hubspot::Contact.new(id: contact.hs_object_id, properties: hubspot_properties )
hubspot_contact.changes? # false

# update a custom field "last_contacted"
# (in the hubspot_contact instance this will be stored in the changes property)
hubspot_contact.last_contacted = Time.now.utc.iso8601
hubspot_contact.changes? # true

# persist the change to hubspot
hubspot_contact.save #true
```

### Listing Objects

You can list all objects (such as contacts) using the `list` method, which returns a `PagedCollection`. This collection handles paginated results and is Enumerable, so responds to methods like `each_page`, `each`, and `all`. You can also pass the `page_size` parameter to control the number of records returned per page.

Example:

```ruby
contacts = Hubspot::Contact.list(page_size: 10)

# Using each_page to iterate over pages, there will be up to 10 contacts per page
contacts.each_page do |page|
  page.each do |contact|
    puts "Contact: #{contact.firstname} #{contact.lastname}"
  end
end

# Or iterate over all contacts and the pagination will be handled transparently (page_size still applies)
contacts.each do |contact|
  puts "Contact: #{contact.firstname} #{contact.lastname}"
end

# Get all contacts at once (use with caution for large datasets)
all_contacts = contacts.all
```

#### Retrieving the first n items:

As mentioned the list method returns a PagedCollection. You can call `first` on the result to retrieve the first item or a specified number of items:

```ruby
contacts_collection = Hubspot::Contact.list

# Retrieve the first contact
first_contact = contacts_collection.first

# Retrieve the first 5 contacts
first_five_contacts = contacts_collection.first(5)
```

This will automatically set the limits and handle paging for the most efficient API calls while honouring the maximum page count for hubspot resources

#### Specifying properties

By default Hubspot will only send back the [default hubspot properties](https://knowledge.hubspot.com/properties/hubspots-default-contact-properties)

You can pass an array of properties to be returned as follows:

Example:

```ruby
# Get the full list of contacts and only return specific properties
contacts = Hubspot::Contact.list(
  properties: ['firstname', 'lastname', 'email', 'mobile', 'custom_property_1']
)

contacts.each do |contact|
  puts "Name: #{contact.firstname} #{contact.lastname}, Email: #{contact.email}, Mobile: #{contact.mobile} CustomerRef: #{contact.custom_property_1}"
end
```

### Searching

You can search for objects by passing query parameters to the `search` method. HubSpot supports several operators such as `eq`, `gte`, `lt`, and `IN` for filtering.

Example:

```ruby
# Search for contacts with email containing "hubspot.com"
contacts = Hubspot::Contact.search(query: { email_contains: 'hubspot.com' })

puts "Searching for Hubspot staff in the contacts CRM"
puts ""

contacts.each do |contact|
  puts "  Found: #{contact.firstname} #{contact.lastname} (#{contact.email})"
end

# Search for companies with number of employees greater than or equal to 100
companies = Hubspot::Company.search(query: { number_of_employees_gte: 100 })

puts "Searching for medium to large companies"
puts ""

companies.each do |company|
  puts "  Found: #{company.name} (#{company.number_of_employees} employees)"
end

# Search for contacts with email in a specific list (IN operator)
contacts = Hubspot::Contact.search(query: { email_in: ['user1@example.com', 'user2@example.com'] })

contacts.each do |contact|
  puts "Found: #{contact.email}"
end
```

### Available Search Operators:
- **contains**: contains <string>
- **neq**: Not equal to.
- **gt**: Greater than.
- **gte**: Greater than or equal to.
- **lt**: Less than.
- **lte**: Less than or equal to.
- **IN**: Matches any of the values in an array.

#### Specifying Properties in Search

When performing a search, you can also specify which properties to return.
*NB* If you specify any properties, you will only get those properties back, and the default HubSpot properties will not be included automatically.

Example:

```ruby
# Search for contacts with email containing "hubspot.com" and only return specific properties
contacts = Hubspot::Contact.search(
  query: { email_contains: 'hubspot.com' },
  properties: ['firstname', 'lastname', 'email', 'mobile', 'custom_property_1']
)

contacts.each do |contact|
  puts "Name: #{contact.firstname} #{contact.lastname}, Email: #{contact.email}, Mobile: #{contact.mobile} CustomerRef: #{contact.custom_property_1}"
end
```

## Working with batches

### Hubspot::Batch

The `Hubspot::Batch` class allows you to perform batch operations on HubSpot resources, such as contacts or companies. This includes batch `create`, `read`, `update`, `upsert`, and `archive` operations. Below are examples of how to use these methods.

#### Batch Create

To create new resources in bulk, you can use the `create` method.

In this example, `batch.create` triggers the creation of new contacts. After creation, the batch response will include the new IDs assigned to each object by HubSpot which will be assigned to the resources in the batch

```ruby
contacts = [
  Hubspot::Contact.new(email: 'new.john@example.com', firstname: 'John', lastname: 'Doe'),
  Hubspot::Contact.new(email: 'new.jane@example.com', firstname: 'Jane', lastname: 'Doe')
]

batch = Hubspot::Batch.new(contacts)
batch.create

batch.resources.each do |contact|
  hubspot_id = contact.id
  # store hubspot_id against a contact....
end
```


#### Batch Read

To read a batch of Objects by their internal hubspot id or by another uniq property you can use the `read` method. You will need to pass the class of the resource, an array of ids and optionally an id_property.

 For simplicity you can also use the `batch_read` method of the corresponding class (e.g. Hubspot::Contacts, Hubspot::Company etc) passing an array of ids and optionally an id_property (defaults to 'id'). This method will return a Hubspot::Batch and the results will be in "resources"

Example using `read` along with the Hubspot id of several companies...

```ruby
# Grab an array of hubspot company ids to read from the api...
company_ids = my_companies.collect(&:hubspot_id).compact

# this will grab all the results from the api handling paging automagically
batch = Hubspot::Batch.read(Hubspot::Company, company_ids)
companies = batch.resources

# Or using the domain field
# Grab an array of company domains
company_domains = my_companies.collect(&:domain_name).compact

# calls /crm/v3/objects/companies/batch/read
batch = Hubspot::Batch.read(Hubspot::Company, company_domains, id_property: 'domain')
companies = batch.resources
```

Example of reading contacts by email and the helper method `batch_read`
By using this method you can page through the results as needed or collect them 

```ruby
email_addresses = my_selected_contacts.collect(&:email).compact

batch = Hubspot::Contact.batch_read(email_addresses, id_property: 'email')

batch.each_page do |contacts|
  contacts.each do |contact|
    # persist some data locally
    update_local_contact_from_hubspot(contact)
  end
  # stop the api calls if a condition is met
  # break if <condition>
end
```

Finally there is another helper method `batch_read_all` on any Hubspot::Resource class (Hubspot::Contact, Hubspot::Company, Hubspot::User etc) which will read all of the resources and return a HubSpot::Batch (with all of the resources). 

You can then update the resources and call `update` on the batch.... see below

#### Batch Update

For updating existing resources in bulk, you can use the `update` method. If you want to locally create an object without calling the API you specify the id and pass any properties in the 'properties' hash (this is how the objects are returned from Hubspot)

```ruby
contacts = [
  Hubspot::Contact.new(id: 1, properties: { firstname: 'John', lastname: 'Doe' }),
  Hubspot::Contact.new(id: 2, properties: { firstname: 'Jane', lastname: 'Doe' })
]

# make a changes to each contact
contacts.each { |contact| contact.last_contacted = Time.now.utc.iso8601 }

batch = Hubspot::Batch.new(contacts)
batch.update
```

Example using a batch
```ruby
user_ids = my_selected_users.collect(&:hubspot_id).compact
batch = Hubspot::User.batch_read(user_ids)

batch.resources.each do |hubspot_user|
  # some logic or method to set any new/changed properties on hubspot_user
  hubspot_user.sales_total = fetch_sales_total(user.email)
end

# now we have a batch with changed resources we can update the batch
batch.update # true
```

#### Batch Upsert

The `upsert` method allows you to insert new records or update existing ones. You’ll need to specify an `id_property` (like `email`) to uniquely identify records

```ruby
contacts = [
  Hubspot::Contact.new(email: 'new.john@example.com', firstname: 'John', lastname: 'Doe'),
  Hubspot::Contact.new(email: 'new.jane@example.com', firstname: 'Jane', lastname: 'Doe')
]

batch = Hubspot::Batch.new(contacts, id_property: 'email')
batch.upsert
```

In this example, if a contact with the given email already exists in HubSpot, it will be updated. If it doesn't, a new contact will be created.

#### Batch Archive

To archive objects in bulk, you can use the `archive` method. This removes the objects from HubSpot.

```ruby
contacts = Hubspot::Contact.search(query: { email_contains: 'hubspot.com' }).all

batch = Hubspot::Batch.new(contacts)
batch.archive
```

The `archive` method sends a batch request to HubSpot to archive the objects. If any of the objects fail to be archived, you can check for partial success using the `partial_success?` method.

#### Error Handling and Success Checks

You can check whether the batch operation was entirely successful, partially successful, or if any failures occurred:

```ruby
if batch.all_successful?
  puts "All resources were successfully processed."
elsif batch.partial_success?
  puts "Some resources were successfully processed, but others failed."
else
  puts "The batch operation failed."
end
```

## Custom Resources

If you have defined custom objects you can easily add them by creating a class that inherits from `Hubspot::Resource`

```ruby
# lib/hubspot/projects.rb

require 'ruby_hubspot_api' # if not required by bundler already...

module Hubspot
  class Project < Resource
    
    # resource_name (part of the url in the api) will default
    # to a simple plural of the class name - in this case 'projects'
    # if the url for your custom object is different you can override it

    def resource_name
      'company_projects'
    end
  end
end

projects = Hubspot::Projects.search(query: { status_in: ['upcoming', 'active', 'overrun'] }).all

```

## Contributing

There is much to do (including writing a TODO list, or at least adding issues in github!) but this should provide a solid start

If you're interested in contributing to the gem, follow the instructions below.

### Developer Setup

A `.env.sample` file is provided with all the environment variables needed for development, including testing credentials. To set up your environment:

1. Copy the `.env.sample` file to `.env`.
2. Update the values with your own credentials (e.g., your `HUBSPOT_ACCESS_TOKEN`).

The `.env` file will be used to configure your access to the HubSpot API and ensure that environment variables are properly loaded during development.

### Using VCR for Testing

We use VCR for recording and replaying HTTP requests during testing. You can control the VCR recording mode by setting the `VCR_RECORD_MODE` environment variable as a string. The following modes are supported:

- `none` (default): No new requests are recorded; only replay from existing cassettes.
- `all`: Records all requests, overwriting existing cassettes.
- `new_episodes`: Records new requests, but keeps existing cassettes unchanged.
- `once`: Records the first time tests are run, and replays on subsequent runs.

You can specify the `VCR_RECORD_MODE` either via the command line or in the `.env` file (see the `.env.sample` file for examples).

To change the record mode on the command line, use:

```bash
$ export VCR_RECORD_MODE=all
```

For more information on how VCR modes work, refer to the [VCR documentation](https://andrewmcodes.gitbook.io/vcr/record_modes).

### Running Tests

To run the tests, simply execute:

```bash
$ rspec
```

Ensure you have your `.env` file configured with a valid `HUBSPOT_ACCESS_TOKEN` for API integration tests if you want to rerecord your interactions.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
