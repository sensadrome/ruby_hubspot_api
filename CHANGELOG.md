
## v0.3.0

- update gem version in lock file
- bump version
- use safe navigation for extracting id
- make erb explicitly determined by the file exension (.json.erb)
- check the env vars before sanitising
- Finish specs
- Sanitize web mock output
- Tests the method missing setter for resource
- find_by_token method - uses v1 API
- Contact find_by_token spec
- Allow ERB in json fixtures
- No cov for inspect
- Ensure properties are passed as named argument
- Update batch spec to check resource_matcher works
- Drop cadacy for now
- Ignore gem files
- Dynamically add a method to batch to allow "resources" to be referred to as the resource_name
- Adds validation for resource matcher
- Bump the version
- Update batch spec
- Clear up processing results
- Fix find resources
- Update the hierarchy to allow more flexibility
- Tidy comments
- Adds  :sparkle: attributes method to a resource
- Improve logic of resource matching
- Update user model to force specific properties to be retrieved
- Add some handling of required properties
- Tidy up somer doc comments
- adjust some rubocop settings
- Yep. Back ported to 2.4
- Tidy up documentation of resource
- Ensure we always apply the right log_level
- Adding Codacy badge
- try to upload the coverage results to codacy too
- Only apply lcov formatter if running on github
- Add property check to the contact spec
- Add read-only properties to resource class
- Adding lcov format
- Using earlier bundler
- adding codecov
- determine if a Hubspot property is read_only (or by negation updatable)
- test on ruby 3.0 too
- ignore ruby version file
- Use ERB in VCR tests so as to be independent of the env vars
- try calling rspec directly
- add ruby 2.5 and reduce log output
- add plaatforms to Gemfile.lock
- fix the github workflow properly
- fix the github workflow
- Create ruby.yml
- More usage clarification
- Clarify usage

## v0.2.0

- bump version
- Update the Readme to add Batch operations
- Adds PagedBatch as pager for batch/read request
- Simplify mocked responses in batch spec
- Move rate limit handling to the client
- add configurable timeouts to requests
- Add api client logging spec
- Cover the previously nocov'd code
- Tidy up resource code
- Adds create and archive methods to batches
- Add all end points to the batch spec
- Ensure keys are stringified
- Adds instance method resource_name on resource
- Adds a changes? Method on resource
- logger.debug the post body and response body
- batch implemntation
- Borrowing Object#blank? method cos it actually really helps...
- batch  :sparkle: upsert spec
- update lock
- describe find_by method
- Bump the version again
- Get the development dependencies right!

## v0.1.2

- bump version
- update changelog and Gemfile.lock
- Sure the search param is values where passing an array
- Fix the Readme

## v0.1.1

- bump version
- Fix dependencies
- adds the version numbers to the gemspec

## v0.1.0

- Update the changeling and link in gem spec
- Improve the intialiser
- Flatten the properties array into a comma separated list
- Test that we only get the properties we ask for or the defaults
- When we use limit(1) we should only return the object not an array
- Reorder and clarify Readme
- Update the sample .env file
- Update the specs for 100% coverage
- Use the Hubspot::Property class to return properties for a given resource object
- Adds a find_by mechanism for resources
- Update Paged request handling based on method
- Adds a dummy Hubspot::Property class
- Add a configured? method to Hubspot module
- Adds user model (aliased to Owner) and specs
- Test all parts of the config code
- Update exception handing logic and add more exception classes
- Log api requests and add interface to set logging
- Update Readme
- Fix rubocop config
- allow connections if vcr_record_mode is on
- MIT license
- Readme file
- console with configuration if env vars set
- Sample ENV file for developers
- Contact/search cassette
- VCR configuration
- Add interface for search
- Adds list method to return PagedCollection
- Update required files
- Adds Hubspot configuration to tests
- Adds PagedCollection for paged results (list / search)
- company model and spec with cassettes
- Cassettes for contact spec
- Contact class with spec
- Initial bases class Resource for api crud
- Load api client and add exception handler
- don't test for client id
- Version spec
- Set the auth headers when access_token configured
- Adds spec for config
- Setup the configuration block

