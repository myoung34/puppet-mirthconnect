require 'spec_helper'

describe 'mirthconnect' do
  context 'Amazon Linux instance' do
    let(:facts) {{ 
      :operatingsystem => 'Amazon',
      :osfamily => 'RedHat',
    }}
  
    let(:title) { 'mirthconnect' }
  
    # Possible RSpec-Puppet bug: expect { include... }.to raise_error... is the correct format
    # However, that passes incorrectly.
    it {
      expect {
        should contain_class('mirthconnect')
      }.to raise_error(Puppet::Error, /operating system is not supported/)
    }
  end

  context 'RedHat instance' do
    let (:resource_file) { 'spec/classes/resources/pw_reset_default.txt' }

    context 'mysql db provider' do
      let(:params) {{
        'admin_password' => 'admin',
        'db_dbname'      => 'mirthdb',
        'db_host'        => 'localhost',
        'db_pass'        => 'foo',
        'db_port'        => '3306',
        'db_provider'    => 'mysql',
        'db_user'        => 'mirth',
        'provider'       => 'rpm',
      }}

      let(:facts) {{ 
        :operatingsystem => 'RedHat',
        :osfamily => 'RedHat',
      }}
    
      let(:title) { 'mirthconnect' }
    
      let(:firewall_params) { {
        'action' => 'accept',
        'port'   => [ 8080, 8443 ],
        'proto'  => 'tcp'
      } }
      it { should contain_firewall('106 allow mirthconnect').with(firewall_params) }
    
      it { should contain_class('java').with_distribution('jdk') }
      it { should contain_package('mirthconnect').with_ensure('latest').with_require(/Class\[Java\]/).with_provider('rpm') }
      it { should contain_file('/etc/init.d/mirthconnect').with_ensure('link').with_target('/opt/mirthconnect/mcservice') }
      it { should contain_exec('ConfSetDb').with_command(/database = mysql/).with_require('Package[mirthconnect]').with_unless(/grep.*database.*=.*mysql/) }
      it { should contain_exec('ConfSetDbUrl').with_command(/database.url = jdbc:mysql:.*localhost.*3306.*mirthdb/).with_require('Package[mirthconnect]').with_unless(/grep.*database.url.*=.*localhost.*3306.*mirthdb/) }
      it { should contain_exec('ConfSetDbUser').with_command(/database.username = mirth/).with_require('Package[mirthconnect]').with_unless(/grep.*database.username.*=.*mirth/) }
      it { should contain_exec('ConfSetDbPass').with_command(/database.password = foo/).with_require('Package[mirthconnect]').with_unless(/grep.*database.password.*=.*foo/) }
  
      let(:service_params) { {
        'ensure'     => 'running',
        'enable'     => 'true',
        'hasrestart' => 'true',
        'hasstatus'  => 'true',
        'require'    => [
          'Package[mirthconnect]',
          'File[/etc/init.d/mirthconnect]',
        ]
      } }
      it { should contain_service('mirthconnect').with(service_params) }
    
      let(:file_pw_reset_params) { {
        'ensure'    => 'present',
        'content'   => File.read(resource_file),
        'replace'   => 'true',
        'subscribe' => 'Package[mirthconnect]',
      } }
      it { should contain_file('/tmp/mirthconnect_pw_reset').with(file_pw_reset_params) }
    
      let(:exec_reset_pw_params) { {
        'command'     => "sleep 60; /opt/mirthconnect/mccommand -u admin -p admin -s /tmp/mirthconnect_pw_reset",
        'refreshonly' => 'true',
        'subscribe'   => 'File[/tmp/mirthconnect_pw_reset]',
      } }
      it { should contain_exec('set mirthconnect password').with(exec_reset_pw_params) }
    end

    context 'derby db provider' do
      let(:params) {{
        'admin_password' => 'admin',
        'db_provider'    => 'derby',
        'provider'       => 'rpm',
      }}

      let(:facts) {{ 
        :operatingsystem => 'RedHat',
        :osfamily => 'RedHat',
      }}
    
      let(:title) { 'mirthconnect' }
    
      let(:firewall_params) { {
        'action' => 'accept',
        'port'   => [ 8080, 8443 ],
        'proto'  => 'tcp'
      } }
      it { should contain_firewall('106 allow mirthconnect').with(firewall_params) }
    
      it { should contain_class('java').with_distribution('jdk') }
      it { should contain_package('mirthconnect').with_ensure('latest').with_require(/Class\[Java\]/).with_provider('rpm') }
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
          'Package[mirthconnect]',
          'File[/etc/init.d/mirthconnect]',
        ]
      } }
      it { should contain_service('mirthconnect').with(service_params) }
    
      let(:file_pw_reset_params) { {
        'ensure'    => 'present',
        'content'   => File.read(resource_file),
        'replace'   => 'true',
        'subscribe' => 'Package[mirthconnect]',
      } }
      it { should contain_file('/tmp/mirthconnect_pw_reset').with(file_pw_reset_params) }
    
      let(:exec_reset_pw_params) { {
        'command'     => "sleep 60; /opt/mirthconnect/mccommand -u admin -p admin -s /tmp/mirthconnect_pw_reset",
        'refreshonly' => 'true',
        'subscribe'   => 'File[/tmp/mirthconnect_pw_reset]',
      } }
      it { should contain_exec('set mirthconnect password').with(exec_reset_pw_params) }
    end

    context 'invalid db provider' do
      let(:params) {{
        'admin_password' => 'admin',
        'db_provider'    => 'foo',
        'provider'       => 'rpm',
      }}

      let(:facts) {{ 
        :operatingsystem => 'RedHat',
        :osfamily => 'RedHat',
      }}
    
      let(:title) { 'mirthconnect' }
    
      let(:firewall_params) { {
        'action' => 'accept',
        'port'   => [ 8080, 8443 ],
        'proto'  => 'tcp'
      } }

      # Possible RSpec-Puppet bug: expect { include... }.to raise_error... is the correct format
      # However, that passes incorrectly.
      it {
        expect {
          should contain_class('mirthconnect')
        }.to raise_error(Puppet::Error, /Unsupported database provider .* supplied/)
      }
    end
  end
end

describe 'mirthconnect' do
  context 'no parameters given' do
    it_should_behave_like "mirthconnect"
  end

  context 'parameters given' do
    it_should_behave_like "mirthconnect", 'bar', 'yum'
  end
end
