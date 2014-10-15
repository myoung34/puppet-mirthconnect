puppet-mirthconnect
================
![Build Status](https://travis-ci.org/myoung34/puppet-mirthconnect.png?branch=master,dev)&nbsp;[![Coverage Status](https://coveralls.io/repos/myoung34/puppet-mirthconnect/badge.png)](https://coveralls.io/r/myoung34/puppet-mirthconnect)&nbsp;[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/myoung34/puppet-mirthconnect/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

Puppet Module For Marklogic

About
=====

[Mirth Connect](http://www.mirthcorp.com) allows applications to communicate with disparate health information systems using a wide variety of protocols and messaging systems. It supports Windows, OSX, and RHEL/CentOS distributions, while this module is aimed at CentOS only (untested on RHEL).

Supported Versions (tested)
=================
## OS ##
* CentOS 6
    * Mirth Connect Base install (Mirth Connect not pre-installed)
        * 3.0.2.7140.b1159

Prerequisites
=============

1. Yum repository with Mirth Connect RPMs available (The EULA does not allow redistribution) if using the 'yum' provider (see usage).
1. Valid license information

Quick Start
===========

1. Via Yum

        yumrepo { "my mirth repo":
           baseurl  => "http://server/pulp/repos/mirthconnect/",
           descr    => "My Mirth Connect Repository",
           enabled  => 1,
           gpgcheck => 0,
         }
        class { 'mirthconnect':
          provider => 'yum',
        }

2. Via RPM (default)

        class { 'mirthconnect::mirthconnect':
          provider       => 'rpm' # RPM is the default.
          rpm_source     => 'www.foo.com/mirth-1.2.1.rpm' # change the source RPM
          admin_password => 'foo',
        }

Hiera
=====

    mirthconnect::admin_password: 'admin'
    mirthconnect::rpm_source:     'www.foo.com/mirth.rpm'
    mirthconnect::provider:       'rpm'
    
Testing
=====

* Run the default tests (puppet + lint)
     
        bundle install 
        bundle exec rake

* Run the [beaker](https://github.com/puppetlabs/beaker) acceptance tests

Due to licensing issues, I cannot distribute the MirthConnect RPM.

        $ for i in `ls spec/acceptance/*_spec.rb`; do echo $i; MIRTH_YUM_URL=http://my.foo.com/yum/ bundle exec rspec $i | grep -A 150 Destroying\ vagrant\ boxes; done
