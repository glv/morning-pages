require 'morning-pages'

require 'webmock/rspec'

describe 'config' do
  subject { MorningPages::Config.new('new-folder/file', 'http://morning-pages.me/api') }
  let(:params) {{ :username => "test", :email => "test@example.com" }}
  let(:yaml) { params.to_yaml }
  before do
    FileUtils.stub(:mkdir_p)
  end
  context 'not pre-existing' do
    before do
      File.stub(:exists? => false)
    end

    it 'creates the folder' do
      FileUtils.should_receive(:mkdir_p).with("new-folder")
      subject
    end

    it 'is not registered' do
      subject.should_not be_registered
    end

    context 'saving to file' do
      let(:file) { double }
      before do
        File.stub(:open).with('new-folder/file', 'w').and_yield(file)
        file.stub(:write)
        stub_request(:post, "http://morning-pages.me/api/register").
          to_return(:status => 200, :body => %{{"key":"abcde"}}, :headers => { "Content-type" => "application/json"})
      end

      it 'writes the file with a key from the server' do
        file.should_receive(:write).with(params.merge(:key => 'abcde').to_yaml)
        subject.register!(:username => 'test', :email => 'test@example.com').should be_true
      end

      it 'returns message on timeout' do
        stub_request(:post, "http://morning-pages.me/api/register").to_timeout
        subject.register!(:username => 'test', :email => 'test@example.com').should be_false
      end

      it 'returns false on failed request' do
        stub_request(:post, "http://morning-pages.me/api/register").to_return(:status => 406)
        subject.register!(:username => 'test', :email => 'test@example.com').should be_false
      end
    end

    context 'posting stats' do
      it 'posts them to the website' do
        stub_request(:post, "http://morning-pages.me/api/stats").
          to_return(:status => 200, :body => %{OK})
        subject.post_stats!(:count => 4, :average_length => 2.1).should be_true
      end

      it 'returns a failure if there was a problem' do
        stub_request(:post, "http://morning-pages.me/api/stats").
          to_return(:status => 500)
        subject.post_stats!(:count => 4, :average_length => 2.1).should be_false
        stub_request(:post, "http://morning-pages.me/api/stats").to_timeout
        subject.post_stats!(:count => 4, :average_length => 2.1).should be_false
      end
    end
  end

  context 'with an existing folder but no file' do
    before do
      File.stub(:exists?).with('new-folder').and_return(true)
      File.stub(:exists?).with('new-folder/file').and_return(false)
    end

    it 'does not create the folder' do
      FileUtils.should_not_receive(:mkdir_p)
      subject
    end

    it 'is not registered' do
      subject.should_not be_registered
    end
  end

  context 'with existing file' do
    before do
      File.stub(:exists? => true)
      File.stub(:read => yaml)
    end

    it 'is registered' do
      subject.should be_registered
    end
  end
end
