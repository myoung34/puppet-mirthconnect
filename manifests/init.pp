# == Class: mirthconnect
#
# This class installs the Mirthconnect server.
#
# === Variables
#
# === Examples
#
#  class { 'mirthconnect':
#    provider => 'rpm' # Rpm is the default.
#  }
#
#  class { 'mirthconnect::mirthconnect':
#    provider => 'rpm' # RPM is the default.
#    source   => 'www.foo.com/mirth-1.2.1.rpm' # change the source RPM
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
# Marcus Young <marcus.young@icainformatics.com>
#
# === Copyright
#
# Copyright 2005-2014 ICA
#
class mirthconnect (
  $admin_password = $mirthconnect::params::admin_password,
  $provider       = $mirthconnect::params::provider,
  $rpm_source     = $mirthconnect::params::rpm_source,
) inherits mirthconnect::params {
  class { 'mirthconnect':
    admin_password => $admin_password,
    provider       => $provider,
  }
}
