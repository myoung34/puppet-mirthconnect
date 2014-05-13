# == Class mirthconnect::mirthconnect
#
# This define handles the packages and prerequisites for installing Mirthconnect.
#
# === Parameters
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
# Copyright 2005-2014 ICA
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
    distribution => 'jdk',
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
