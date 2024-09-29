## v.0.2.0

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
- #5 batch_updating

## v0.1.2

- initial setup
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
- adds the version numbers to the gemspec
- Fix dependencies
- bump version
- Fix the Readme
- Sure the search param is values where passing an array
- update changelog and Gemfile.lock
- bump version

## v0.1.1

- Fix the Readme
- Sure the search param is values where passing an array
- update changelog and Gemfile.lock
- bump version

## v0.1.0

- adds the version numbers to the gemspec
- Fix dependencies
- bump version
