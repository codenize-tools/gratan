describe 'Gratan::Client#export' do
  context 'when there id no user' do
    subject { client }

    it do
      expect(subject.export.strip).to eq ''
    end
  end
end
