describe 'Gratan::Client#export' do
  context 'when function exists' do
    let(:grantfile) {
      <<-RUBY
user "scott", "%" do
  on "*.*" do
    grant "USAGE"
  end

  on "FUNCTION #{TEST_DATABASE}.my_func" do
    grant "EXECUTE"
  end
end
      RUBY
    }

    subject { client }

    before do
      mysql do |cli|
        drop_database(cli)
        create_database(cli)
        create_function(cli, :my_func)
      end

      apply(subject) do
        grantfile
      end
    end

    it do
      expect(subject.export.strip).to eq grantfile.strip
    end
  end

  context 'when procedure exists' do
    let(:grantfile) {
      <<-RUBY
user "scott", "%" do
  on "*.*" do
    grant "USAGE"
  end

  on "PROCEDURE #{TEST_DATABASE}.my_prcd" do
    grant "EXECUTE"
  end
end
      RUBY
    }

    subject { client }

    before do
      mysql do |cli|
        drop_database(cli)
        create_database(cli)
        create_procedure(cli, :my_prcd)
      end

      apply(subject) do
        grantfile
      end
    end

    it do
      expect(subject.export.strip).to eq grantfile.strip
    end
  end
end
