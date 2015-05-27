describe 'Gratan::Client#apply' do
  before(:each) do
    mysql do |cli|
      drop_database(cli)
      create_database(cli)
      create_function(cli, :my_func)
      create_procedure(cli, :my_prcd)
    end
  end

  context 'when func -> prcd' do
    subject { client }

    before do
      apply(subject) {
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

    end

    it do
      apply(subject) {
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

      expect(show_grants).to match_array [
        "GRANT USAGE ON *.* TO 'scott'@'%'",
        "GRANT EXECUTE ON PROCEDURE `#{TEST_DATABASE}`.`my_prcd` TO 'scott'@'%'"
      ]
    end
  end

  context 'when prcd -> func' do
    subject { client }

    before do
      apply(subject) {
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

    end

    it do
      apply(subject) {
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

      expect(show_grants).to match_array [
        "GRANT USAGE ON *.* TO 'scott'@'%'",
        "GRANT EXECUTE ON FUNCTION `#{TEST_DATABASE}`.`my_func` TO 'scott'@'%'"
      ]
    end
  end
end
