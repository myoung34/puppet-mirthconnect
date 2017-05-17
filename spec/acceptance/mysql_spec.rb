require 'spec_helper_acceptance'

describe 'mirthconnect class' do
  describe 'install via yum' do
    it 'works with no errors' do
      pp = <<-EOS
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
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      expect(apply_manifest(pp, catch_failures: true).exit_code).to be_zero

      shell('rpm -qa | grep mirthconnect') do |result|
        assert_match %r{^mirthconnect}, result.stdout, 'Mirthconnect package install was not successful.'
      end

      shell("echo user list > /tmp/test_cmd; /opt/mirthconnect/mccommand -u admin -p admin -s /tmp/test_cmd | tail -n 2 | head -n 1 | awk '{ print $2 }'") do |result|
        assert_match %r{^admin}, result.stdout, 'MirthConnect did not set a proper admin password, or is not running/connectable.'
      end

      shell("mysql -umirth -pmirthdbpass mirthdb -e 'SELECT USERNAME FROM PERSON;' | grep -v '^+' | tail -n +2") do |result|
        assert_match 'admin', result.stdout, 'MirthConnect did not properly initialize mysql as its data store.'
      end

      shell("mysql -umirth -pmirthdbpass mirthdb -e 'SELECT USERNAME FROM person;' | grep -v '^+' | tail -n +2") do |result|
        assert_match 'admin', result.stdout, 'MirthConnect does not allow case insensitive tables.'
      end

      shell("mysql -umirth -pmirthdbpass mirthdb -e 'SELECT USERNAME FROM person;' | grep -v '^+' | tail -n +2 | wc -l") do |result|
        assert_match '1', result.stdout, 'MySQL has more than one user in the `person` table.'
      end
    end
  end
end
