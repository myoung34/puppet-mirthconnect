# == Class: mirthconnect
#
# This class installs the Mirthconnect server.
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
# [*provider*]
#   The provider to download the MirthConnect package from. 
#   Can be one of 'rpm', 'source', or 'yum'.
#
# [*rpm_source*]
#   The source of the RPM if using the 'rpm' provider.
#
# [*tarball_source*]
#   Optional source of the source tarball.
#   Not optional if using the 'source' provider.
#
# === Examples
#
#  class { 'mirthconnect':
#    provider => 'rpm' # Rpm is the default.
#  }
#
#  class { 'mirthconnect::mirthconnect':
#    provider     => 'rpm' # RPM is the default.
#    rpm_source   => 'www.foo.com/mirth-1.2.1.rpm' # change the source RPM
#  }
#
#  # Install via yum. This must be accessible to the client as a prerequisite via the EULA.
#  class { 'mirthconnect':
#    provider => 'yum',
#  }
#
#  # Install but change the administrator password.
#  class { 'mirthconnect':
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
class mirthconnect (
  $admin_password = $mirthconnect::params::admin_password,
  $db_dbname      = $mirthconnect::params::db_dbname,
  $db_host        = $mirthconnect::params::db_host,
  $db_pass        = $mirthconnect::params::db_pass,
  $db_port        = $mirthconnect::params::db_port,
  $db_provider    = $mirthconnect::params::db_provider,
  $db_user        = $mirthconnect::params::db_user,
  $provider       = $mirthconnect::params::provider,
  $rpm_source     = $mirthconnect::params::rpm_source,
  $tarball_source = $mirthconnect::params::tarball_source,
) inherits mirthconnect::params {
  class { 'mirthconnect::mirthconnect':
    admin_password => $admin_password,
    db_dbname      => $db_dbname,
    db_host        => $db_host,
    db_pass        => $db_pass,
    db_port        => $db_port,
    db_provider    => $db_provider,
    db_user        => $db_user,
    provider       => $provider,
    rpm_source     => $rpm_source,
    tarball_source => $tarball_source,
  }
}
