describe 'Gratan::Client#export' do
  context 'when chunked by user' do
    subject { client(chunk_by_user: true) }

    before do
      apply(subject) do
        <<-RUBY
user "scott", "%" do
  on "*.*" do
    grant "USAGE"
  end

  on "test.*" do
    grant "SELECT"
  end

  on "test3.*" do
    grant "UPDATE"
  end
end

user "scott", "localhost" do
  on "*.*" do
    grant "USAGE"
  end

  on "test2.*" do
    grant "INSERT"
  end

  on "test3.*" do
    grant "DELETE"
  end
end
        RUBY
      end
    end

    it do
      expect(subject.export.strip).to eq <<-RUBY.strip
user "scott", ["%", "localhost"] do
  on "*.*" do
    grant "USAGE"
  end

  on "test.*" do
    grant "SELECT"
  end

  on "test2.*" do
    grant "INSERT"
  end

  on "test3.*" do
    grant "DELETE"
    grant "UPDATE"
  end
end
      RUBY
    end
  end
end
