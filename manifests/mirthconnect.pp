# == Class mirthconnect::mirthconnect
#
# This define handles the packages and prerequisites for installing Mirthconnect.
#
# === Parameters
#
# [*admin_password*]
#   The password to set the admin password to post-install.
#
# [*provider*]
#   The provider to download the MirthConnect package from. Can
#   Be 'yum' or 'rpm'.
#
# [*source*]
#   The source of the RPM if using the 'rpm' provider.
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
#    provider => 'rpm' # RPM is the default.
#    source   => 'www.foo.com/mirth-1.2.1.rpm' # change the source RPM
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
# Marcus Young <marcus.young@icainformatics.com>
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
  $provider       = $mirthconnect::provider,
  $rpm_source     = $mirthconnect::params::rpm_source,
) {
  firewall { '106 allow mirthconnect':
    action => accept,
    port   => [
      8080, 8443
    ],
    proto  => tcp,
  }

  class { 'java':
    version => 'present',
    package => 'java-1.7.0-openjdk',
  }

  case $provider {
    'rpm': {
      package { 'mirthconnect':
        ensure   => latest,
        provider => rpm,
        require  => Class['java'],
        source   => $rpm_source,
      }
    }
    'yum': {
      package { 'mirthconnect':
        ensure   => latest,
        provider => yum,
        require  => Class['java'],
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

  service { 'mirthconnect':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
      Package['mirthconnect'],
      File['/etc/init.d/mirthconnect'],
    ],
  }

  file { '/tmp/mirthconnect_pw_reset':
    ensure      => present,
    content     => template('mirthconnect/mirthconnect_pw_reset.erb'),
    replace     => true,
    subscribe   => Package['mirthconnect'],
  }

  exec { 'set mirthconnect password':
    command     => 'sleep 30; /opt/mirthconnect/mccommand -u admin -p admin -s /tmp/mirthconnect_pw_reset',
    path        => $::path,
    refreshonly => true,
    subscribe   => File['/tmp/mirthconnect_pw_reset'],
  }

  Class['java'] -> Package['mirthconnect'] -> Service['mirthconnect'] -> File['/tmp/mirthconnect_pw_reset'] -> Exec['set mirthconnect password']
}
