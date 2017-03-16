# LTI 2.1 Reference Tool Provider
An LTI tool provider intended to be used as a reference for implementing the IMS LTI 2.1 specification. Section numbers in the comments (i.e. “6.1.2”) refer to sections of the IMS LTI 2.1 specification.

## Setup
1. `bundle install`
2. `bundle exec rake db:create`
3. `bundle exec rake db:migrate`
4. `bundle exec rackup`

## Working with Canvas
The varaible substitutions in this tool are considered "restriced capabilities" by Canvas. this means that they can only be used if the following steps are taken:

### 1. Create a Custom Tool Consumer Profile in Canvas
Create a new `DeveloperKey` via Canvas Rails console (this should be done in siteadmin if this is for a deployed environment)
```
k = DeveloperKey.new
```
Create a new custom Tool Consumer Profile associated with the developer key
```
tcp = Lti::ToolConsumerProfile.create!(developer_key: k)
```
Add the needed capabilities to the custom Tool Consumer Profile
```
tcp.capabilities = ['Canvas.account.name', 'Canvas.course.id', ... ]
tcp.save!
```
### 2. Substitute Values
Substitute your new `DeveloperKey` global ID in the following places of this tool:
- lti_controller:19
- lti_controller:27

Substitute your new `DeveloperKey`'s `api_key` in the following place in this tool:
- lti_controller:20

## Running Tests
1. `bundle exec rake db:migrate RACK_ENV=test`
2. `bundle exec rspec`
