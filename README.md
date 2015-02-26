puppet-mirthconnect
================
![Build Status](https://travis-ci.org/myoung34/puppet-mirthconnect.png?branch=master,dev)&nbsp;
[![Coverage Status](https://coveralls.io/repos/myoung34/puppet-mirthconnect/badge.png)](https://coveralls.io/r/myoung34/puppet-mirthconnect)&nbsp;
[![Puppet Forge](https://img.shields.io/puppetforge/v/myoung34/mirthconnect.svg)](https://forge.puppetlabs.com/myoung34/mirthconnect)
[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/myoung34/puppet-mirthconnect/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

Puppet Module For Mirthconnect

About
=====

[Mirth Connect](http://www.mirthcorp.com) allows applications to communicate with disparate health information systems using a wide variety of protocols and messaging systems. It supports Windows, OSX, and RHEL/CentOS distributions, while this module is aimed at CentOS only (untested on RHEL).

Supported Versions (tested)
=================
## OS ##
* AWS Linux
    * Mirth Connect Base install (Mirth Connect not pre-installed)
        * 3.0.2.7140.b1159 (from source only)
* CentOS 6
    * Mirth Connect Base install (Mirth Connect not pre-installed)
        * 3.0.2.7140.b1159

Prerequisites
=============

1. Yum repository with Mirth Connect RPMs available (The EULA does not allow redistribution) if using the 'yum' provider (see usage).
1. Valid license information

Parameters
===========
* *admin_password*
 * The password to set the admin password to post-install.
* *db_dbname*
 * Optional database name for mirth to use in the mirth.properties file.
 * Not optional if the *db_provider* is set to anything but 'derby'
* *db_host*
 * Optional database hostname for mirth to use in the mirth.properties file.
 * Not optional if the *db_provider* is set to anything but 'derby'
* *db_pass*
 * Optional database password for mirth to use in the mirth.properties file.
 * Not optional if the *db_provider* is set to anything but 'derby
* *db_port*
 * Optional database port for mirth to use in the mirth.properties file.
 * Not optional if the *db_provider* is set to anything but 'derby'
* *db_provider*
 * Optional database provider for mirth to use in the mirth.properties file.
 *  Currently the only valid strings are 'derby' or 'mysql'
* *db_user*
 * Optional database user for mirth to use in the mirth.properties file.
 * Not optional if the *db_provider* is set to anything but 'derby'
* *provider*
 * The provider to download the MirthConnect package from. Can be one of 'rpm', 'source', or 'yum'.
* *rpm_source*
 * The source of the RPM if using the 'rpm' provider.
* *tarball_source*
 * Optional source of the source tarball.
 * Not optional if using the 'source' provider.

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
        
3. Using MySQL instead of derby

        $override_options = {
          'mysqld' => {
            'lower_case_table_names' => '1' ,
          }
        }
        
        $mysql_root_password = 'somerootpass'
        $mirthdbuser = 'mirth'
        $mirthdbpass = 'mirthdbpass'
        $mirthdbname = 'mirthdb'
        
        class { '::mysql::server':
          root_password    => $mysql_root_password ,
          override_options => $override_options ,
        }->
        
        mysql::db { $mirthdbname:
          user     => $mirthdbuser,
          password => $mirthdbpass,
          host     => 'localhost',
        }
        
        class {'mirthconnect':
          db_host        => 'localhost',
          db_user        => $mirthdbuser,
          db_pass        => $mirthdbpass,
          db_provider    => 'mysql',
          db_port        => '3306',
          db_dbname      => $mirthdbname,
          admin_password => $mirth_admin_password,
          provider       => 'rpm',
        }
        
        Mysql_grant["${mirthdbuser}@localhost/${mirthdbname}.*"] -> Service['mirthconnect']

Hiera
=====

    mirthconnect::admin_password: 'admin'
    mirthconnect::db_dbname:      'mirthdb'
    mirthconnect::db_host:        'localhost'
    mirthconnect::db_pass:        'abc1234'
    mirthconnect::db_port:        '3306'
    mirthconnect::db_provider:    'mysql'
    mirthconnect::db_user:        'mirth'
    mirthconnect::provider:       'rpm'
    mirthconnect::rpm_source:     'www.foo.com/mirth.rpm'
    mirthconnect::tarball_source: 'www.foo.com/mirth.tar.gz'

Testing
=====

* Run the default tests (puppet + lint)

        bundle install
        bundle exec rake

* Run the [beaker](https://github.com/puppetlabs/beaker) acceptance tests

Due to licensing issues, I cannot distribute the MirthConnect RPM.

        $ for i in `ls spec/acceptance/*_spec.rb`; do echo $i; MIRTH_YUM_URL=http://my.foo.com/yum/ bundle exec rspec $i | grep -A 150 Destroying\ vagrant\ boxes; done
