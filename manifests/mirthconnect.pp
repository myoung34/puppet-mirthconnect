# == Class mirthconnect::mirthconnect
#
# This define handles the packages and prerequisites for installing Mirthconnect.
#
# === Parameters
#
# [*admin_password*]
#   The password to set the admin password to post-install.
#
# [*db_dbname*]
#   Optional database name for mirth to use in the mirth.properties file.
#   Not optional if the *db_provider* is set to anything but 'derby'
#
# [*db_host*]
#   Optional database hostname for mirth to use in the mirth.properties file.
#   Not optional if the *db_provider* is set to anything but 'derby'
#
# [*db_pass*]
#   Optional database password for mirth to use in the mirth.properties file.
#   Not optional if the *db_provider* is set to anything but 'derby'
#
# [*db_port*]
#   Optional database port for mirth to use in the mirth.properties file.
#   Not optional if the *db_provider* is set to anything but 'derby'
#
# [*db_provider*]
#   Optional database provider for mirth to use in the mirth.properties file.
#   Currently the only valid strings are 'derby' or 'mysql'
#
# [*db_user*]
#   Optional database user for mirth to use in the mirth.properties file.
#   Not optional if the *db_provider* is set to anything but 'derby'
#
# [*java_version*]
#   Optional java version to install. Defaults to 'java-1.8.0-openjdk'
#
# [*provider*]
#   The provider to download the MirthConnect package from.
#   Can be one of 'rpm', 'source', or 'yum'.
#
# [*rpm_source*]
#   Optional source of the RPM.
#   Not optional if using the 'rpm' provider.
#
# [*tarball_source*]
#   Optional source of the source tarball.
#   Not optional if using the 'source' provider.
#
# === Examples
#
# Provide some examples on how to use this type:
#
#  class { 'mirthconnect::mirthconnect':
#    provider => 'rpm' # RPM is the default.
#  }
#
#  class { 'mirthconnect::mirthconnect':
#    provider     => 'rpm' # RPM is the default.
#    rpm_source   => 'www.foo.com/mirth-1.2.1.rpm' # change the source RPM
#  }
#
#  # Install via yum. This must be accessible to the client as a prerequisite via the EULA.
#  class { 'mirthconnect::mirthconnect':
#    provider => 'yum',
#  }
#
#  # Install but change the administrator password.
#  class { 'mirthconnect::mirthconnect':
#    admin_password => 'foo',
#  }
#
# === Authors
#
# Marcus Young <myoung34@my.apsu.edu>
#
# === Copyright
#
# The MIT License (MIT)
#
# Copyright (c) 2014 Marcus Young
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in
#   all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#   THE SOFTWARE.
#
class mirthconnect::mirthconnect (
  $admin_password = $mirthconnect::admin_password,
  $db_dbname      = $mirthconnect::params::db_dbname,
  $db_host        = $mirthconnect::params::db_host,
  $db_pass        = $mirthconnect::params::db_pass,
  $db_port        = $mirthconnect::params::db_port,
  $db_provider    = $mirthconnect::params::db_provider,
  $db_user        = $mirthconnect::params::db_user,
  $java_version   = $mirthconnect::params::java_version,
  $provider       = $mirthconnect::provider,
  $rpm_source     = $mirthconnect::params::rpm_source,
  $tarball_source = $mirthconnect::params::tarball_source,
) {
  if $::osfamily == 'RedHat' {
    if $::operatingsystem =~ /Amazon/ {
      if $provider != 'source' {
        fail("AWS Linux does not support package source ${provider}")
      }
    }
  } else {
    fail('Your operating system is not supported')
  }

  class { 'java':
    version => 'present',
    package => $java_version,
  }

  firewall { '106 allow mirthconnect':
    action => accept,
    port   => [
      8080, 8443
    ],
    proto  => tcp,
  }

  case $provider {
    'source': {
      package { 'faraday_middleware':
          ensure   => 'installed',
          provider => 'gem',
      }->

      archive { '/tmp/mirthconnect.tar.gz':
        ensure       => present,
        before       => File['/etc/init.d/mirthconnect'],
        extract      => true,
        extract_path => '/opt',
        source       => $tarball_source,
        cleanup      => true,
      }->

      file { '/opt/mirthconnect':
        ensure => link,
        target => '/opt/Mirth Connect',
      }
    }
    'rpm': {
      package { 'mirthconnect':
        ensure   => latest,
        before   => [
          File['/opt/mirthconnect'],
          File['/etc/init.d/mirthconnect'],
        ],
        provider => rpm,
        require  => [
          Class['java'],
        ],
        source   => $rpm_source,
      }

      file { '/opt/mirthconnect':
        ensure => directory,
      }

      if($rpm_source =~ /3.4.0.8000.b1959/) {
        file { '/tmp/mirth_340_fix.sh':
          ensure  => present,
          before  => Exec['set mirthconnect password'],
          content => template('mirthconnect/mirth_340_fix.sh.erb'),
          require => Package['mirthconnect'],
        }

        exec { 'fix mirth 3.4.0 install':
          before  => Exec['set mirthconnect password'],
          command => 'bash /tmp/mirth_340_fix.sh',
          creates => '/opt/mirthconnect/cli-lib/jersey-common-2.22.1.jar',
          path    => $::path,
          require => File['/tmp/mirth_340_fix.sh'],
        }
      }
    }
    'yum': {
      package { 'mirthconnect':
        ensure   => latest,
        before   => [
          File['/opt/mirthconnect'],
          File['/etc/init.d/mirthconnect'],
        ],
        require  => [
          Class['java'],
        ],
        provider => yum,
      }

      file { '/opt/mirthconnect':
        ensure => directory,
      }
    }
    default: {
      fail("Unsupported provider ${provider}")
    }
  }

  file { '/etc/init.d/mirthconnect':
    ensure => link,
    target => '/opt/mirthconnect/mcservice',
  }

  case $db_provider {
    'derby': {
    }
    'mysql': {
      $properties_file = '/opt/mirthconnect/conf/mirth.properties'
      exec { 'ConfSetDb':
        before  => Service['mirthconnect'],
        command => "sed -i.bak 's/database \\?=.*/database = mysql/g' ${properties_file}",
        path    => $::path,
        require => File['/opt/mirthconnect'],
        unless  => "grep -E 'database\s*=\s*mysql' ${properties_file}",
      }
      exec { 'ConfSetDbUrl':
        before  => Service['mirthconnect'],
        command => "sed -i.bak 's/database.url \\?=.*/database.url = jdbc:mysql:\\/\\/${db_host}:${db_port}\\/${db_dbname}/g' ${properties_file}",
        path    => $::path,
        require => File['/opt/mirthconnect'],
        unless  => "grep -E 'database.url\s*=\s*jdbc:mysql://${db_host}:${db_port}/${db_dbname}' ${properties_file}",
      }
      exec { 'ConfSetDbUser':
        before  => Service['mirthconnect'],
        command => "sed -i.bak 's/database.username \\?=.*/database.username = ${db_user}/g' ${properties_file}",
        path    => $::path,
        require => File['/opt/mirthconnect'],
        unless  => "grep -E 'database.username\s*=\s*${db_user}' ${properties_file}",
      }
      exec { 'ConfSetDbPass':
        before  => Service['mirthconnect'],
        command => "sed -i.bak 's/database.password \\?=.*/database.password = ${db_pass}/g' ${properties_file}",
        path    => $::path,
        require => File['/opt/mirthconnect'],
        unless  => "grep -E 'database.password\s*=\s*${db_pass}' ${properties_file}",
      }
    }
    default: {
      fail("Unsupported database provider '${db_provider}' supplied.")
    }
  }

  service { 'mirthconnect':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
      File['/etc/init.d/mirthconnect'],
    ],
  }

  file { '/tmp/mirthconnect_pw_reset':
    ensure    => present,
    content   => template('mirthconnect/mirthconnect_pw_reset.erb'),
    replace   => true,
    subscribe => Service['mirthconnect'],
  }

  exec { 'set mirthconnect password':
    command     => 'sleep 60; /opt/mirthconnect/mccommand -u admin -p admin -s /tmp/mirthconnect_pw_reset',
    path        => $::path,
    refreshonly => true,
    subscribe   => File['/tmp/mirthconnect_pw_reset'],
  }

  Package <| |> -> Archive <| |> -> Exec <| |>
}
