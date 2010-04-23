require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Trinidad::Extensions::SandboxServerExtension do
  subject { Trinidad::Extensions::SandboxServerExtension.new({}) }

  before(:each) do
    @tomcat = Trinidad::Tomcat::Tomcat.new
  end

  it 'includes a default path for the sandbox' do
    opts = subject.prepare_options
    opts[:context_path].should == '/sandbox'
  end

  it 'allows to override the default path' do
    ext = Trinidad::Extensions::SandboxServerExtension.new({
      :context_path => '/trinidad'
    })

    ext.prepare_options[:context_path].should == '/trinidad'
  end

  it 'adds a new application to the host' do
    subject.configure(@tomcat)

    @tomcat.host.findChildren().should have(1).children
  end

  it 'gives privileges to the applications context' do
    subject.configure(@tomcat)

    @tomcat.host.findChildren().first.privileged.should be_true
  end
end
