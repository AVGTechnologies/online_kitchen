Online Kitchen
==============

Setup
-----

      bundle install
      rake db:setup


Development
-----------

Example of curl with proper params:

     curl -i -X PUT curl -i -H 'UserName: franta.lopata' \
       -H 'AUTHENTICATIONTOKEN: secret' \
       -H "Accept: application/json" \
       -H "Content-Type: application/json" \
       -d '{ "nic": "neco" }' \
       http://localhost:4567/api/v1/configurations/123

