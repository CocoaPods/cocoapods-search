require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Search do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ search }).should.be.instance_of Command::Search
      end
    end
  end
end

