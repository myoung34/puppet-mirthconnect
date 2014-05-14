# == Class: mirthconnect
#
# This class installs the Mirthconnect server.
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
  $provider       = $mirthconnect::params::provider,
  $rpm_source     = $mirthconnect::params::rpm_source,
) inherits mirthconnect::params {
  class { 'mirthconnect::mirthconnect':
    admin_password => $admin_password,
    provider       => $provider,
    rpm_source     => $rpm_source,
  }
}
