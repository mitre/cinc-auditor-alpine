# CINC Auditor Alpine Container Validation Profile
# This profile is executed FROM WITHIN the container being tested
#
# Run with input file:
#   docker run --rm -v $(pwd)/test:/test cinc-auditor-alpine:6 \
#     cinc-auditor exec /test/integration --input-file=/test/integration/inputs-v6.yml

control 'cinc-auditor-installation' do
  impact 1.0
  title 'CINC Auditor is installed and functional'
  desc "Verify CINC Auditor binary exists and reports expected version #{input('cinc_version')}.x"

  describe command('cinc-auditor version') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/#{Regexp.escape(input('cinc_version'))}\.\d+/) }
  end
end

control 'expected-plugins-installed' do
  impact 1.0
  title 'Expected plugins are installed'
  desc "Verify all expected plugins are properly installed"

  plugin_list_output = command('cinc-auditor plugin list').stdout

  input('expected_plugins').each do |plugin_name|
    describe "Plugin #{plugin_name}" do
      subject { plugin_list_output }
      it { should match(/#{Regexp.escape(plugin_name)}/) }
    end
  end
end

control 'kubectl-installation' do
  impact 1.0
  title 'kubectl is installed and functional'
  desc "Verify kubectl binary exists and reports version #{input('kubectl_version')}.x"

  describe command('kubectl version --client') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/Client Version.*#{Regexp.escape(input('kubectl_version'))}/) }
  end
end

control 'ruby-version' do
  impact 0.7
  title 'Ruby version is installed'
  desc "Verify Ruby #{input('ruby_version')}.x is installed"

  describe command('ruby --version') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/ruby #{Regexp.escape(input('ruby_version'))}\.\d+/) }
  end
end

control 'required-directories' do
  impact 0.5
  title 'Required directories exist'
  desc 'Verify essential directories are present in the container'

  describe directory('/root/.kube') do
    it { should exist }
  end

  describe directory('/root/.inspec') do
    it { should exist }
  end

  describe directory('/workspace') do
    it { should exist }
  end
end

control 'git-workspace-initialized' do
  impact 0.3
  title 'Git repository initialized in workspace'
  desc 'Verify git repository exists in /workspace to suppress InSpec warnings'

  describe directory('/workspace/.git') do
    it { should exist }
  end
end

control 'environment-variables' do
  impact 0.5
  title 'Required environment variables are set'
  desc 'Verify container has required environment variables configured'

  describe os_env('TRAIN_K8S_SESSION_MODE') do
    its('content') { should eq 'true' }
  end

  describe os_env('KUBECONFIG') do
    its('content') { should eq '/root/.kube/config' }
  end
end
