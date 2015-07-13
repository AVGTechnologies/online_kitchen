Online Kitchen
==============

Setup
-----

 1. copy and setup config files:

      cp config/database.yml.example config/database.yml
      cp config/online_kitchen.yml.example config/online_kitchen.yml
      cp config/templates.yml.example config/templates.yml

 2. install all dependant libraries and init db:

      bundle install
      rake db:setup

  3. Follow Procfile (in production)


Development
-----------

Example of curl with proper params:

For following examples you can run server in devel by `rackup`.

* Get list of Configuration (for user franta.lopata):

     curl -i -H 'UserName: franta.lopata' \
       -H 'AUTHENTICATIONTOKEN: secret' -H "Accept: application/json" \
       -H  "Content-Type: application/json" \
       http://localhost:9292/api/v1/configurations

* Create new configuration:

     curl -i -X POST -H 'UserName: franta.lopata' \
       -H 'AUTHENTICATIONTOKEN: secret' -H "Accept: application/json" \
       -H "Content-Type: application/json" \
       -d '{ "configuration": {"name": "configurationName", "folder_name": "_online_kitnech_test"}}'
       http://localhost:9292/api/v1/configurations

* Update Configuration:

 * add machine:

     curl -i -X PUT -H 'UserName: franta.lopata' \
       -H 'AUTHENTICATIONTOKEN: secret' \
       -H "Accept: application/json" \
       -H "Content-Type: application/json" \
       -d '{ "configuration": { "machines_attributes": [{ "name": "MachineName1", "template": "travis_7x86"}] }}' \
       http://localhost:9292/api/v1/configurations/44

 * destroy machine (switch machine to `destroy_queued` state and schedule destroying):

     curl -i -X PUT -H 'UserName: franta.lopata' \
       -H 'AUTHENTICATIONTOKEN: secret' \
       -H "Accept: application/json" \
       -H "Content-Type: application/json" \
       -d '{ "configuration": { "machines_attributes": [{ "id": 22, "_destroy": "1"}] }}' \
       http://localhost:9292/api/v1/configurations/44


* Destroy configuration (e.g. schedule destroy)

     curl -i -X DELETE -H 'UserName: franta.lopata' \
       -H 'AUTHENTICATIONTOKEN: secret' \
       -H "Accept: application/json" \
       -H "Content-Type: application/json" \
       http://localhost:4567/api/v1/configurations/1


Error Handling
--------------

Service raises following exceptions:
* 400 JSON::ParserError (not implemented yet)
* 404 Record not Found
* 422 InvalidRecord and/or Validation Error
* 500 Application error - this means error in code

Example of validation error response:

     {
       "status": "unprocessable_entity",
       "errors": {
         "name": "is too short (minimum is 3 characters)"
       }
     }

Setup IRB
---------

     rails
     > OnlineKitchen.setup
     > # for FactoryGirl
     > require 'factory_girl'
     > require './spec/factories'


FAQ
---
1. If you have problem with downloading vagrant box

     vagrant box add --insecure 'ubuntu/trusty64' https://atlas.hashicorp.com/ubuntu/boxes/trusty64/versions/14.04/providers/virtualbox.box

