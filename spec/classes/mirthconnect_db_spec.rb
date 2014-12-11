require 'spec_helper'

shared_context "mirthconnect" do |admin_password = nil, provider = 'rpm', resource_file = nil|
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
      'provider'       => provider,
    }}
    resource_file = "spec/classes/resources/pw_reset_#{admin_password}.txt"
  end

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
        should include_class('mirthconnect')
      }.to raise_error(Puppet::Error, /operating system is not supported/)
    }
  end

  context 'RedHat instance' do
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
    it { should contain_package('mirthconnect').with_ensure('latest').with_require(/Class\[Java\]/).with_provider(provider) }
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
end

describe 'mirthconnect' do
  context 'no parameters given' do
    it_should_behave_like "mirthconnect"
  end

  context 'parameters given' do
    it_should_behave_like "mirthconnect", 'bar', 'yum'
  end
end
