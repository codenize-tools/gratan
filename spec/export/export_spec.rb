describe 'Gratan::Client#export' do
  context 'when user does not exist' do
    subject { client }

    it do
      expect(subject.export.strip).to eq ''
    end
  end

  context 'when user exists' do
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

user "scott", "localhost" do
  on "*.*" do
    grant "USAGE"
  end

  on "test.*" do
    grant "SELECT"
  end
end
      RUBY
    }

    subject { client }

    before do
      apply(subject) do
        grantfile
      end
    end

    it do
      expect(subject.export.strip).to eq grantfile.strip
    end
  end

  context 'when ignore user exists' do
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

    subject { client(ignore_user: /\Abob\z/) }

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
      RUBY
    end
  end

  context 'when with option exists' do
    let(:grantfile) {
      <<-RUBY
user "scott", "%" do
  on "*.*", :with=>"GRANT OPTION" do
    grant "USAGE"
  end
end
      RUBY
    }

    subject { client(ignore_user: /\Abob\z/) }

    before do
      apply(subject) do
        grantfile
      end
    end

    it do
      expect(subject.export.strip).to eq grantfile.strip
    end
  end
end
