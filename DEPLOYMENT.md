
Set up production machine
=========================

     sudo locale-gen en_US en_US.UTF-8 cs_CZ.UTF-8
     sudo dpkg-reconfigure locales

     sudo apt-get install git-core
     sudo apt-get install build-essential
     git config --global url."https://github.com".insteadOf git://github.com

     curl -sSL https://rvm.io/mpapis.asc | gpg --import -
     curl -sSL https://get.rvm.io | bash -s stable --ruby
     source /home/vagrant/.rvm/scripts/rvm


     sudo apt-get install libpq-dev
     sudo apt-get install sqlite3
