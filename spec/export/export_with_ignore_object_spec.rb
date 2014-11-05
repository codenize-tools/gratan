describe 'Gratan::Client#export' do
  context 'when with ignore_object' do
    let(:grantfile) {
      <<-RUBY
user "scott", "%" do
  on "*.*" do
    grant "USAGE"
  end

  on "test.*" do
    grant "SELECT"
  end
end

user "bob", "localhost" do
  on "*.*" do
    grant "USAGE"
  end

  on "test.*" do
    grant "SELECT"
  end
end
      RUBY
    }

    subject { client(ignore_object: /test/) }

    before do
      apply(subject) do
        grantfile
      end
    end

    it do
      expect(subject.export.strip).to eq <<-RUBY.strip
user "scott", "%" do
  on "*.*" do
    grant "USAGE"
  end
end

user "bob", "localhost" do
  on "*.*" do
    grant "USAGE"
  end
end
      RUBY
    end
  end

  context 'when with ignore_object (2)' do
    let(:grantfile) {
      <<-RUBY
user "scott", "%" do
  on "*.*" do
    grant "USAGE"
  end

  on "test.*" do
    grant "SELECT"
  end
end

user "bob", "localhost" do
  on "*.*" do
    grant "USAGE"
  end

  on "test.*" do
    grant "SELECT"
  end
end
      RUBY
    }

    subject { client(ignore_object: /bob/) }

    before do
      apply(subject) do
        grantfile
      end
    end

    it do
      expect(subject.export.strip).to eq <<-RUBY.strip
user "scott", "%" do
  on "*.*" do
    grant "USAGE"
  end

  on "test.*" do
    grant "SELECT"
  end
end

user "bob", "localhost" do
  on "*.*" do
    grant "USAGE"
  end

  on "test.*" do
    grant "SELECT"
  end
end
      RUBY
    end
  end
end
