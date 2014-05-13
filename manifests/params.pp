# Class: mirthconnect::params
#
# This module manages mirthconnect parameters.
#
# Parameters:
#
# There are no default parameters for this class.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# This class file is not called directly
class mirthconnect::params {
  $admin_password = 'admin'
  $provider = 'rpm'
  $rpm_source = 'http://downloads.mirthcorp.com/connect/3.0.2.7140.b1159/mirthconnect-3.0.2.7140.b1159-linux.rpm'
}
