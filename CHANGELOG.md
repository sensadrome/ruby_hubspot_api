
## v0.3.0

- Clarify usage
- More usage clarification
- Create ruby.yml
- fix the github workflow
- fix the github workflow properly
- add plaatforms to Gemfile.lock
- add ruby 2.5 and reduce log output
- try calling rspec directly
- Use ERB in VCR tests so as to be independent of the env vars
- ignore ruby version file
- test on ruby 3.0 too
- determine if a Hubspot property is read_only (or by negation updatable)
- adding codecov
- Using earlier bundler
- Adding lcov format
- Add read-only properties to resource class
- Add property check to the contact spec
- Only apply lcov formatter if running on github
- try to upload the coverage results to codacy too
- Adding Codacy badge
- Ensure we always apply the right log_level
- Tidy up documentation of resource
- Yep. Back ported to 2.4
- adjust some rubocop settings
- Tidy up somer doc comments
- Add some handling of required properties
- Update user model to force specific properties to be retrieved
- Improve logic of resource matching
- Adds  :sparkle: attributes method to a resource
- Tidy comments
- Update the hierarchy to allow more flexibility
- Fix find resources
- Clear up processing results
- Update batch spec
- Bump the version
- Adds validation for resource matcher
- Dynamically add a method to batch to allow "resources" to be referred to as the resource_name
- Ignore gem files
- Drop cadacy for now
- Update batch spec to check resource_matcher works
- Ensure properties are passed as named argument
- No cov for inspect
- Allow ERB in json fixtures
- Contact find_by_token spec
- find_by_token method - uses v1 API
- Tests the method missing setter for resource
- Sanitize web mock output
- Finish specs
- check the env vars before sanitising
- make erb explicitly determined by the file exension (.json.erb)
- use safe navigation for extracting id
- bump version
- update gem version in lock file

## v0.2.0

- Get the development dependencies right!
- Bump the version again
- describe find_by method
- update lock
- batch  :sparkle: upsert spec
- Borrowing Object#blank? method cos it actually really helps...
- batch implemntation
- logger.debug the post body and response body
- Adds a changes? Method on resource
- Adds instance method resource_name on resource
- Ensure keys are stringified
- Add all end points to the batch spec
- Adds create and archive methods to batches
- Tidy up resource code
- Cover the previously nocov'd code
- Add api client logging spec
- add configurable timeouts to requests
- Move rate limit handling to the client
- Simplify mocked responses in batch spec
- Adds PagedBatch as pager for batch/read request
- Update the Readme to add Batch operations
- bump version

## v0.1.2

- Fix the Readme
- Sure the search param is values where passing an array
- update changelog and Gemfile.lock
- bump version

## v0.1.1

- adds the version numbers to the gemspec
- Fix dependencies
- bump version

## v0.1.0

- Setup the configuration block
- Adds spec for config
- Set the auth headers when access_token configured
- Version spec
- don't test for client id
- Load api client and add exception handler
- Initial bases class Resource for api crud
- Contact class with spec
- Cassettes for contact spec
- company model and spec with cassettes
- Adds PagedCollection for paged results (list / search)
- Adds Hubspot configuration to tests
- Update required files
- Adds list method to return PagedCollection
- Add interface for search
- VCR configuration
- Contact/search cassette
- Sample ENV file for developers
- console with configuration if env vars set
- Readme file
- MIT license
- allow connections if vcr_record_mode is on
- Fix rubocop config
- Update Readme
- Log api requests and add interface to set logging
- Update exception handing logic and add more exception classes
- Test all parts of the config code
- Adds user model (aliased to Owner) and specs
- Add a configured? method to Hubspot module
- Adds a dummy Hubspot::Property class
- Update Paged request handling based on method
- Adds a find_by mechanism for resources
- Use the Hubspot::Property class to return properties for a given resource object
- Update the specs for 100% coverage
- Update the sample .env file
- Reorder and clarify Readme
- When we use limit(1) we should only return the object not an array
- Test that we only get the properties we ask for or the defaults
- Flatten the properties array into a comma separated list
- Improve the intialiser
- Update the changeling and link in gem spec

