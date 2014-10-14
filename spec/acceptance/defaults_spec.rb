require 'spec_helper_acceptance'

describe 'mirthconnect class' do
  describe 'install via yum' do
    it 'should work with no errors' do
      pp = <<-EOS
        class { 'mirthconnect':
        }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero

      shell("rpm -qa | grep mirthconnect") do |result|
        assert_match /^mirthconnect/, result.stdout, 'Mirthconnect package install was not successful.'
      end

      shell("echo user list > /tmp/test_cmd; /opt/mirthconnect/mccommand -u admin -p admin -s /tmp/test_cmd | tail -n 2 | head -n 1 | awk '{ print $2 }'") do |result|
        assert_match /^admin/, result.stdout, 'MirthConnect did not set a proper admin password, or is not running/connectable.'
      end
      
    end
  end
end
