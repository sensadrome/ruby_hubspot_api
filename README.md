# Ruby HubSpot API Gem

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

```ruby
Hubspot.configure do |config|
  config.access_token = 'your_access_token'
end
```

This configuration ensures that your API requests are authenticated using your HubSpot access token.

## Working with Objects

This gem allows you to interact with HubSpot objects such as contacts and companies. You can perform operations on individual instances (e.g., creating or updating records) as well as on collections (e.g., listing or searching).

### Instance Methods

#### Creating and Saving an Object

You can instantiate a new resource (such as a contact) by passing a hash of properties when creating the object. After setting the properties, calling `save` will persist the object to the HubSpot API.

Example:

```ruby
new_contact = Hubspot::Contact.new(firstname: 'John', lastname: 'Doe', email: 'john.doe@example.com')

# Save the contact to HubSpot
new_contact.save

# After saving, the contact will be assigned an ID by the API
puts "New contact ID: #{new_contact.id}"
```

#### Updating an Existing Object

To update an existing object, you can either modify the object and call `save`, or use the `update` method specifying the properties you want to update

Example using `save`:

```ruby
contact = Hubspot::Contact.find(1)
contact.lastname = 'DoeUpdated'
contact.save # true
```

Example using `update`:

```ruby
contact = Hubspot::Contact.find(1)
contact.update(lastname: 'DoeUpdated') # true
```

### Class Methods

#### Listing Objects

You can list all objects (such as contacts) using the `list` method, which returns a `PagedCollection`. This collection handles paginated results and responds to methods like `each_page`, `each`, and `all`. You can also pass the `page_size` parameter to control the number of records returned per page.

Example:

```ruby
contacts = Hubspot::Contact.list(page_size: 10)

# Using each_page to iterate over pages
contacts.each_page do |page|
  page.each do |contact|
    puts "Contact: #{contact.firstname} #{contact.lastname}"
  end
end

# Or iterate over all contacts without worrying about pagination
contacts.each do |contact|
  puts "Contact: #{contact.firstname} #{contact.lastname}"
end

# Get all contacts at once (use with caution for large datasets)
all_contacts = contacts.all
```

#### Retrieving the first n items

You can use the `first` method to retrieve the first item or a specified number of items:

```ruby
contacts = Hubspot::Contact.list(page_size: 10)

# Retrieve the first contact
first_contact = contacts.first

# Retrieve the first 5 contacts
first_five_contacts = contacts.first(5)
```

This will automatically set the limits and handle paging for the most efficient API calls while honouring the maximum page count for hubspot resources

#### Searching

You can search for objects by passing query parameters to the `search` method. HubSpot supports several operators such as `eq`, `gte`, `lt`, and `IN` for filtering.

Example:

```ruby
# Search for contacts with email containing "hubspot.com"
contacts = Hubspot::Contact.search(query: { email_contains: 'hubspot.com' })

contacts.each do |contact|
  puts "Found: #{contact.email}"
end

# Search for companies with number of employees greater than or equal to 100
companies = Hubspot::Company.search(query: { number_of_employees_gte: 100 })

companies.each do |company|
  puts "Found: #{company.name}, Employees: #{company.number_of_employees}"
end

# Search for contacts with email in a specific list (IN operator)
contacts = Hubspot::Contact.search(query: { email_in: ['user1@example.com', 'user2@example.com'] })

contacts.each do |contact|
  puts "Found: #{contact.email}"
end
```

### Available Search Operators:
- **eq**: Equal to.
- **neq**: Not equal to.
- **gte**: Greater than or equal to.
- **lte**: Less than or equal to.
- **IN**: Matches any of the values in an array.

#### Specifying Properties in Search

When performing a search, you can also specify which properties to return. If you specify any properties, you will only get those properties back, and the default HubSpot properties will not be included automatically.

Example:

```ruby
# Search for contacts with email containing "hubspot.com" and only return specific properties
contacts = Hubspot::Contact.search(
  query: { email_contains: 'hubspot.com' },
  properties: ['firstname', 'lastname', 'email', 'mobile', 'custom_property_1']
)

contacts.each do |contact|
  puts "Name: #{contact.firstname} #{contact.lastname}, Email: #{contact.email}, Mobile: #{contact.mobile}"
end
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
