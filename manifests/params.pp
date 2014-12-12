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
class mirthconnect::params {
  $admin_password = 'admin'
  $db_dbname = ''
  $db_host = ''
  $db_pass = ''
  $db_port = ''
  $db_provider = 'derby'
  $db_user = ''
  $provider = 'rpm'
  $rpm_source = 'http://downloads.mirthcorp.com/connect/3.0.2.7140.b1159/mirthconnect-3.0.2.7140.b1159-linux.rpm'
  $tarball_source = 'http://downloads.mirthcorp.com/connect/3.0.2.7140.b1159/mirthconnect-3.0.2.7140.b1159-unix.tar.gz'
}
