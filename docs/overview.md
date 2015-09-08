Introduction to Online Kitchen
==============================

Online Kitchen is internal AVG service, which allows shielding the users
from specifics of virtual infrastructure by providing interface for
management of so called "configurations".

By configuration we understand collection of machines, specified by template.

The primary motivation for this project was to provide helper service
for manual testers - they can specify which machines they want to use
and they can deploy them.

Users of Online Kitchen do not communicate with the service directly, but
they use nifty web interface to perform all the actions.

Thanks to REST API design, Online Kitchen can be used as part of custom GUI 
solution.

How can I use this?
-------------------

You will need to use different backend for machine provisioning, for example
[fog](https://github.com/fog/fog). In future, the low level machine service, called LabManager, will
be replaced with OpenSource solution as well.

Other things you will need to do will be custom config files, to better match
your requirements and needs. You can find them in /configs/.

Communication
-------------
Communication is REST based, with data being transferred in JSON format.
You can see the examples in README.md

Classes
=======

Main classes
------------
**OnlineKitchen** takes care of general project setup, such as DB and reporting.
**App** exposes the REST interface.

Models
------
**Configuration** represents machine configuration.
**Machine** represents single machine in configuration.
**User** contains metadata for OnlineKitchen user.

Low level management
--------------------
**LabManagerProvision** takes care of machine provisioning via **LabManager**
**LabManagerRelease** takes care of machine releasing via **LabManager**