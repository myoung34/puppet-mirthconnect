require 'spec_helper'

shared_context 'database' do |osfamily, operatingsystem, operatingsystemrelease, db_provider, db_host, db_port, db_user, db_pass, db_dbname|
  let(:facts) do
    {
      'osfamily'               => osfamily,
      'operatingsystem'        => operatingsystem,
      'operatingsystemrelease' => operatingsystemrelease,
    }
  end
  let(:params) do
    {
      'provider'    => 'source',
      'db_provider' => db_provider,
      'db_host'     => db_host,
      'db_port'     => db_port,
      'db_user'     => db_user,
      'db_pass'     => db_pass,
      'db_dbname'  => db_dbname
    }
  end

  if db_provider == 'derby'
    it { is_expected.not_to contain_exec('ConfSetDb') }
    it { is_expected.not_to contain_exec('ConfSetDbUrl') }
    it { is_expected.not_to contain_exec('ConfSetDbUser') }
    it { is_expected.not_to contain_exec('ConfSetDbPass') }
  elsif db_provider == 'mysql'
    it { is_expected.to contain_exec('ConfSetDb').with_command(%r{database = #{db_provider}}).with_require('File[/opt/mirthconnect]').with_unless(%r{grep.*database.*=.*#{db_provider}}).with_before('Service[mirthconnect]').with_require('File[/opt/mirthconnect]') }
    it { is_expected.to contain_exec('ConfSetDbUrl').with_command(%r{database.url = jdbc:mysql:.*#{db_host}.*#{db_port}.*#{db_dbname}}).with_require('File[/opt/mirthconnect]').with_unless(%r{grep.*database.url.*=.*#{db_host}.*#{db_port}.*#{db_dbname}}).with_before('Service[mirthconnect]').with_require('File[/opt/mirthconnect]') }
    it { is_expected.to contain_exec('ConfSetDbUser').with_command(%r{database.username = #{db_user}}).with_require('File[/opt/mirthconnect]').with_unless(%r{grep.*database.username.*=.*#{db_user}}).with_before('Service[mirthconnect]').with_require('File[/opt/mirthconnect]') }
    it { is_expected.to contain_exec('ConfSetDbPass').with_command(%r{database.password = #{db_pass}}).with_require('File[/opt/mirthconnect]').with_unless(%r{grep.*database.password.*=.*#{db_pass}}).with_before('Service[mirthconnect]').with_require('File[/opt/mirthconnect]') }
  else
    it {
      expect do
        is_expected.to contain_package('mirthconnect')
      end.to raise_error(Puppet::Error, %r{Unsupported database provider})
    }
  end
end

shared_context 'mirthconnect source' do |osfamily, operatingsystem, operatingsystemrelease|
  let(:facts) do
    {
      'osfamily'               => osfamily,
      'operatingsystem'        => operatingsystem,
      'operatingsystemrelease' => operatingsystemrelease,
    }
  end
  let(:params) do
    {
      'provider' => 'source'
    }
  end

  it { is_expected.to contain_package('faraday_middleware').with_ensure('installed').with_provider('gem') }
  let(:archive_params) do
    {
      'ensure' => 'present',
      'before' => [
        'File[/etc/init.d/mirthconnect]',
        'File[/opt/mirthconnect]',
        'Exec[set mirthconnect password]'
      ],
      'extract'      => 'true',
      'extract_path' => '/opt',
      'source'       => %r{tar\.gz$},
      'cleanup'      => 'true'
    }
  end

  it { is_expected.to contain_archive('/tmp/mirthconnect.tar.gz').with(archive_params) }
  it { is_expected.to contain_file('/opt/mirthconnect').with_ensure('link').with_target('/opt/Mirth Connect') }
end

shared_context 'mirthconnect redhat' do |provider, osfamily, operatingsystem, operatingsystemrelease|
  let(:facts) do
    {
      'osfamily'               => osfamily,
      'operatingsystem'        => operatingsystem,
      'operatingsystemrelease' => operatingsystemrelease,
    }
  end
  let(:params) do
    {
      'provider' => provider
    }
  end

  if osfamily == 'RedHat'
    if operatingsystem == 'Amazon'
      it {
        expect do
          is_expected.to contain_package('mirthconnect')
        end.to raise_error(Puppet::Error, %r{AWS Linux does not support package source})
      }
    else
      it { is_expected.to contain_package('mirthconnect').with_ensure('latest').with_provider(provider) }
      it { is_expected.to contain_file('/opt/mirthconnect').with_ensure('directory') }
    end
  end
end

shared_context 'mirthconnect' do |admin_password = nil, osfamily, operatingsystem, operatingsystemrelease|
  let(:facts) do
    {
      'osfamily'               => osfamily,
      'operatingsystem'        => operatingsystem,
      'operatingsystemrelease' => operatingsystemrelease,
    }
  end
  if admin_password.nil?
    # Override as params default for later, but don't push
    # It into params hash to ensure defaults match up.
    admin_password = 'admin'
    resource_file = 'spec/classes/resources/pw_reset_default.txt'
  else
    # Keep what they passed in and use it as the parameters
    # To ensure parameter passing works as expected.
    let(:params) do
      {
        'admin_password' => admin_password,
        'provider' => 'source'
      }
    end

    resource_file = "spec/classes/resources/pw_reset_#{admin_password}.txt"
  end

  if osfamily != 'RedHat'
    it {
      expect do
        is_expected.to contain_class('mirthconnect')
      end.to raise_error(Puppet::Error, %r{Your operating system is not supported})
    }
  end
  let(:firewall_params) do
    {
      'action' => 'accept',
      'port'   => [8080, 8443],
      'proto'  => 'tcp'
    }
  end
  it { is_expected.to contain_firewall('106 allow mirthconnect').with(firewall_params) }

  it { is_expected.to contain_class('java').with_distribution('jdk') }

  it { is_expected.to contain_file('/etc/init.d/mirthconnect').with_ensure('link').with_target('/opt/mirthconnect/mcservice') }
  it { is_expected.not_to contain_exec('ConfSetDb') }
  it { is_expected.not_to contain_exec('ConfSetDbUrl') }
  it { is_expected.not_to contain_exec('ConfSetDbUser') }
  it { is_expected.not_to contain_exec('ConfSetDbPass') }

  let(:service_params) do
    {
      'ensure' => 'running',
      'enable'     => 'true',
      'hasrestart' => 'true',
      'hasstatus'  => 'true'
    }
  end
  it { is_expected.to contain_service('mirthconnect').with(service_params) }

  let(:file_pw_reset_params) do
    {
      'ensure' => 'present',
      'content'   => File.read(resource_file),
      'replace'   => 'true',
      'subscribe' => 'Service[mirthconnect]'
    }
  end
  it { is_expected.to contain_file('/tmp/mirthconnect_pw_reset').with(file_pw_reset_params) }

  let(:exec_reset_pw_params) do
    {
      'command' => 'sleep 60; /opt/mirthconnect/mccommand -u admin -p admin -s /tmp/mirthconnect_pw_reset; mysql -uroot mirthdb -e "insert into person_preference (PERSON_ID,NAME,VALUE) values (1,\'firstlogin\',\'false\');"',
      'refreshonly' => 'true',
      'subscribe'   => 'File[/tmp/mirthconnect_pw_reset]'
    }
  end

  it { is_expected.to contain_exec('set mirthconnect password').with(exec_reset_pw_params) }
end

describe 'mirthconnect' do
  describe 'AWS Linux' do
    context 'rpm provider' do
      it_behaves_like 'mirthconnect redhat', 'rpm', 'RedHat', 'Amazon', '2017.03'
      it_behaves_like 'mirthconnect', 'bar', 'RedHat', 'Amazon', '2017.03'

      describe 'database' do
        context 'derby db' do
          it_behaves_like 'database', 'RedHat', 'Amazon', '2017.03', 'derby'
        end

        context 'mysql db' do
          it_behaves_like 'database', 'RedHat', 'Amazon', '2017.03', 'mysql', 'localhost', '3306', 'dbusername', 'secure123', 'mirthdb'
        end

        context 'unknown db' do
          it_behaves_like 'database', 'RedHat', 'Amazon', '2017.03', 'watdb'
        end
      end
    end

    context 'yum provider' do
      it_behaves_like 'mirthconnect redhat', 'yum', 'RedHat', 'Amazon', '2017.03'
      it_behaves_like 'mirthconnect', 'bar', 'RedHat', 'Amazon', '2017.03'

      describe 'database' do
        context 'derby db' do
          it_behaves_like 'database', 'RedHat', 'Amazon', '2017.03', 'derby'
        end

        context 'mysql db' do
          it_behaves_like 'database', 'RedHat', 'Amazon', '2017.03', 'mysql', 'localhost', '3306', 'dbusername', 'secure123', 'mirthdb'
        end

        context 'unknown db' do
          it_behaves_like 'database', 'RedHat', 'Amazon', '2017.03', 'watdb'
        end
      end
    end

    context 'source provider' do
      it_behaves_like 'mirthconnect source', 'RedHat', 'Amazon', '2017.03'
      it_behaves_like 'mirthconnect', 'bar', 'RedHat', 'Amazon', '2017.03'

      describe 'database' do
        context 'derby db' do
          it_behaves_like 'database', 'RedHat', 'Amazon', '2017.03', 'derby'
        end

        context 'mysql db' do
          it_behaves_like 'database', 'RedHat', 'Amazon', '2017.03', 'mysql', 'localhost', '3306', 'dbusername', 'secure123', 'mirthdb'
        end

        context 'unknown db' do
          it_behaves_like 'database', 'RedHat', 'Amazon', '2017.03', 'watdb'
        end
      end
    end
  end

  describe 'Redhat Linux' do
    context 'rpm provider' do
      it_behaves_like 'mirthconnect redhat', 'rpm', 'RedHat', 'RedHat', '6'
      it_behaves_like 'mirthconnect', 'bar', 'RedHat', 'RedHat', '6'

      describe 'database' do
        context 'derby db' do
          it_behaves_like 'database', 'RedHat', 'RedHat', '6', 'derby'
        end

        context 'mysql db' do
          it_behaves_like 'database', 'RedHat', 'RedHat', '6', 'mysql', 'localhost', '3306', 'dbusername', 'secure123', 'mirthdb'
        end

        context 'unknown db' do
          it_behaves_like 'database', 'RedHat', 'RedHat', '6', 'watdb'
        end
      end
    end

    context 'yum provider' do
      it_behaves_like 'mirthconnect redhat', 'yum', 'RedHat', 'RedHat', '6'
      it_behaves_like 'mirthconnect', 'bar', 'RedHat', 'RedHat', '6'

      describe 'database' do
        context 'derby db' do
          it_behaves_like 'database', 'RedHat', 'RedHat', '6', 'derby'
        end

        context 'mysql db' do
          it_behaves_like 'database', 'RedHat', 'RedHat', '6', 'mysql', 'localhost', '3306', 'dbusername', 'secure123', 'mirthdb'
        end

        context 'unknown db' do
          it_behaves_like 'database', 'RedHat', 'RedHat', '6', 'watdb'
        end
      end
    end

    context 'source provider' do
      it_behaves_like 'mirthconnect source', 'RedHat', 'RedHat', '6'
      it_behaves_like 'mirthconnect', 'bar', 'RedHat', 'RedHat', '6'

      describe 'database' do
        context 'derby db' do
          it_behaves_like 'database', 'RedHat', 'RedHat', '6', 'derby'
        end

        context 'mysql db' do
          it_behaves_like 'database', 'RedHat', 'RedHat', '6', 'mysql', 'localhost', '3306', 'dbusername', 'secure123', 'mirthdb'
        end

        context 'unknown db' do
          it_behaves_like 'database', 'RedHat', 'RedHat', '6', 'watdb'
        end
      end
    end
  end

  describe 'Unknown osfamily' do
    it {
      expect do
        is_expected.to contain_package('mirthconnect')
      end.to raise_error(Puppet::Error, %r{Your operating system is not supported})
    }
  end
end
