require 'spec_helper'

shared_context "database" do |osfamily, operatingsystem, db_provider, db_host, db_port, db_user, db_pass, db_dbname|
  let(:facts) {{
    'osfamily' => osfamily,
    'operatingsystem' => operatingsystem,
  }}
  let(:params) {{
    'provider' => 'source',
    'db_provider' => db_provider,
    'db_host' => db_host,
    'db_port' => db_port,
    'db_user' => db_user,
    'db_pass' => db_pass,
    'db_dbname' => db_dbname,
  }}
  if db_provider == 'derby'
    it { should_not contain_exec('ConfSetDb') }
    it { should_not contain_exec('ConfSetDbUrl') }
    it { should_not contain_exec('ConfSetDbUser') }
    it { should_not contain_exec('ConfSetDbPass') }
  elsif db_provider == 'mysql'
    it { should contain_exec('ConfSetDb').with_command(/database = #{db_provider}/).with_require('File[/opt/mirthconnect]').with_unless(/grep.*database.*=.*#{db_provider}/).with_before('Service[mirthconnect]').with_require('File[/opt/mirthconnect]') }
    it { should contain_exec('ConfSetDbUrl').with_command(/database.url = jdbc:mysql:.*#{db_host}.*#{db_port}.*#{db_dbname}/).with_require('File[/opt/mirthconnect]').with_unless(/grep.*database.url.*=.*#{db_host}.*#{db_port}.*#{db_dbname}/).with_before('Service[mirthconnect]').with_require('File[/opt/mirthconnect]') }
    it { should contain_exec('ConfSetDbUser').with_command(/database.username = #{db_user}/).with_require('File[/opt/mirthconnect]').with_unless(/grep.*database.username.*=.*#{db_user}/).with_before('Service[mirthconnect]').with_require('File[/opt/mirthconnect]') }
    it { should contain_exec('ConfSetDbPass').with_command(/database.password = #{db_pass}/).with_require('File[/opt/mirthconnect]').with_unless(/grep.*database.password.*=.*#{db_pass}/).with_before('Service[mirthconnect]').with_require('File[/opt/mirthconnect]') }
  else
    it {
      expect {
        should contain_package('mirthconnect')
      }.to raise_error(Puppet::Error, /Unsupported database provider/)
    }
  end
end

shared_context "mirthconnect source" do |osfamily, operatingsystem|
  let(:facts) {{
    'osfamily' => osfamily,
    'operatingsystem' => operatingsystem,
  }}
  let(:params) {{
    'provider' => 'source',
  }}

  it { should contain_package('faraday_middleware').with_ensure('installed').with_provider('gem') }
  let(:archive_params) {{
    'ensure'       => 'present',
    'before'       => [
      'File[/etc/init.d/mirthconnect]',
      'File[/opt/mirthconnect]',
      'Exec[set mirthconnect password]',
    ],
    'extract'      => 'true',
    'extract_path' => '/opt',
    'source'       => /tar\.gz$/,
    'cleanup'      => 'true',
   }}
    
  it { should contain_archive('/tmp/mirthconnect.tar.gz').with(archive_params) }
  it { should contain_file('/opt/mirthconnect').with_ensure('link').with_target('/opt/Mirth Connect') }
end

shared_context "mirthconnect redhat" do |provider, osfamily, operatingsystem|
  let(:facts) {{
    'osfamily' => osfamily,
    'operatingsystem' => operatingsystem,
  }}
  let(:params) {{
    'provider' => provider,
  }}

  if osfamily == 'Linux' and operatingsystem == 'Amazon'
    it {
      expect {
        should contain_package('mirthconnect')
      }.to raise_error(Puppet::Error, /AWS Linux does not support package source/)
    }
  else
    it { should contain_package('mirthconnect').with_ensure('latest').with_provider(provider) }
    it { should contain_file('/opt/mirthconnect').with_ensure('directory') }
  end
end

shared_context "mirthconnect" do |admin_password = nil, osfamily, operatingsystem|
  let(:facts) {{
    'osfamily' => osfamily,
    'operatingsystem' => operatingsystem,
  }}
  if admin_password.nil?
    # Override as params default for later, but don't push
    # It into params hash to ensure defaults match up.
    admin_password = 'admin'
    resource_file = 'spec/classes/resources/pw_reset_default.txt'
  else
    # Keep what they passed in and use it as the parameters
    # To ensure parameter passing works as expected.
    let(:params) {{
      'admin_password' => admin_password,
      'provider'       => 'source',
    }}
    resource_file = "spec/classes/resources/pw_reset_#{admin_password}.txt"
  end

  if osfamily != 'RedHat'
    if osfamily != 'Linux' and operatingsystem != 'Amazon'
      it {
        expect {
          should contain_class('mirthconnect')
        }.to raise_error(Puppet::Error, /Your operating system is not supported/)
      }
    end
  end
  let(:firewall_params) { {
    'action' => 'accept',
    'port'   => [ 8080, 8443 ],
    'proto'  => 'tcp'
  } }
  it { should contain_firewall('106 allow mirthconnect').with(firewall_params) }

  if osfamily != 'Linux'
    it { should contain_class('java').with_before('Service[mirthconnect]').with_distribution('jdk') }
  else
    it { should_not contain_class('java') }
  end
  it { should contain_file('/etc/init.d/mirthconnect').with_ensure('link').with_target('/opt/mirthconnect/mcservice') }
  it { should_not contain_exec('ConfSetDb') }
  it { should_not contain_exec('ConfSetDbUrl') }
  it { should_not contain_exec('ConfSetDbUser') }
  it { should_not contain_exec('ConfSetDbPass') }

  let(:service_params) { {
    'ensure'     => 'running',
    'enable'     => 'true',
    'hasrestart' => 'true',
    'hasstatus'  => 'true',
    'require'    => [
      'File[/etc/init.d/mirthconnect]',
    ]
  } }
  it { should contain_service('mirthconnect').with(service_params) }

  let(:file_pw_reset_params) { {
    'ensure'    => 'present',
    'content'   => File.read(resource_file),
    'replace'   => 'true',
    'subscribe' => 'Service[mirthconnect]',
  } }
  it { should contain_file('/tmp/mirthconnect_pw_reset').with(file_pw_reset_params) }

  let(:exec_reset_pw_params) { {
    'command'     => "sleep 60; /opt/mirthconnect/mccommand -u admin -p admin -s /tmp/mirthconnect_pw_reset",
    'refreshonly' => 'true',
    'subscribe'   => 'File[/tmp/mirthconnect_pw_reset]',
  } }
  it { should contain_exec('set mirthconnect password').with(exec_reset_pw_params) }
end

describe 'mirthconnect' do
  describe 'AWS Linux' do
    context 'rpm provider' do
      it_should_behave_like "mirthconnect redhat", 'rpm', 'Linux', 'Amazon'
      it_should_behave_like "mirthconnect", 'bar', 'Linux', 'Amazon'

      describe 'database' do
        context 'derby db' do
          it_should_behave_like 'database', 'Linux', 'Amazon', 'derby'
        end
  
        context 'mysql db' do
          it_should_behave_like 'database', 'Linux', 'Amazon', 'mysql', 'localhost', '3306', 'dbusername', 'secure123', 'mirthdb'
        end
  
        context 'unknown db' do
          it_should_behave_like 'database', 'Linux', 'Amazon', 'watdb'
        end
      end
    end

    context 'yum provider' do
      it_should_behave_like "mirthconnect redhat", 'yum', 'Linux', 'Amazon'
      it_should_behave_like "mirthconnect", 'bar', 'Linux', 'Amazon'

      describe 'database' do
        context 'derby db' do
          it_should_behave_like 'database', 'Linux', 'Amazon', 'derby'
        end
  
        context 'mysql db' do
          it_should_behave_like 'database', 'Linux', 'Amazon', 'mysql', 'localhost', '3306', 'dbusername', 'secure123', 'mirthdb'
        end
  
        context 'unknown db' do
          it_should_behave_like 'database', 'Linux', 'Amazon', 'watdb'
        end
      end
    end
  
    context 'source provider' do
      it_should_behave_like "mirthconnect source", 'Linux', 'Amazon'
      it_should_behave_like "mirthconnect", 'bar', 'Linux', 'Amazon'

      describe 'database' do
        context 'derby db' do
          it_should_behave_like 'database', 'Linux', 'Amazon', 'derby'
        end
  
        context 'mysql db' do
          it_should_behave_like 'database', 'Linux', 'Amazon', 'mysql', 'localhost', '3306', 'dbusername', 'secure123', 'mirthdb'
        end
  
        context 'unknown db' do
          it_should_behave_like 'database', 'Linux', 'Amazon', 'watdb'
        end
      end
    end
  end

  describe 'Redhat Linux' do
    context 'rpm provider' do
      it_should_behave_like "mirthconnect redhat", 'rpm', 'RedHat', 'RedHat'
      it_should_behave_like "mirthconnect", 'bar', 'RedHat', 'RedHat'

      describe 'database' do
        context 'derby db' do
          it_should_behave_like 'database', 'RedHat', 'RedHat', 'derby'
        end
  
        context 'mysql db' do
          it_should_behave_like 'database', 'RedHat', 'RedHat', 'mysql', 'localhost', '3306', 'dbusername', 'secure123', 'mirthdb'
        end
  
        context 'unknown db' do
          it_should_behave_like 'database', 'RedHat', 'RedHat', 'watdb'
        end
      end
    end
  
    context 'yum provider' do
      it_should_behave_like "mirthconnect redhat", 'yum', 'RedHat', 'RedHat'
      it_should_behave_like "mirthconnect", 'bar', 'RedHat', 'RedHat'

      describe 'database' do
        context 'derby db' do
          it_should_behave_like 'database', 'RedHat', 'RedHat', 'derby'
        end
  
        context 'mysql db' do
          it_should_behave_like 'database', 'RedHat', 'RedHat', 'mysql', 'localhost', '3306', 'dbusername', 'secure123', 'mirthdb'
        end
  
        context 'unknown db' do
          it_should_behave_like 'database', 'RedHat', 'RedHat', 'watdb'
        end
      end
    end
  
    context 'source provider' do
      it_should_behave_like "mirthconnect source", 'RedHat', 'RedHat'
      it_should_behave_like "mirthconnect", 'bar', 'RedHat', 'RedHat'

      describe 'database' do
        context 'derby db' do
          it_should_behave_like 'database', 'RedHat', 'RedHat', 'derby'
        end
  
        context 'mysql db' do
          it_should_behave_like 'database', 'RedHat', 'RedHat', 'mysql', 'localhost', '3306', 'dbusername', 'secure123', 'mirthdb'
        end
  
        context 'unknown db' do
          it_should_behave_like 'database', 'RedHat', 'RedHat', 'watdb'
        end
      end
    end
  end

  describe 'Unknown osfamily' do
    it {
      expect {
        should contain_package('mirthconnect')
      }.to raise_error(Puppet::Error, /Your operating system is not supported/)
    }
  end
end
