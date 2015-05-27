describe 'Gratan::Client#apply' do
  context 'when create user with function' do
    subject { client }

    it do
      create_functions(:foo) do
        result = apply(subject) {
          <<-RUBY
  user 'scott', 'localhost' do
    on '*.*' do
      grant 'USAGE'
    end

    on 'FUNCTION #{TEST_DATABASE}.foo' do
      grant 'EXECUTE'
    end
  end
          RUBY
        }

        expect(result).to be_truthy

        expect(show_grants).to match_array [
          "GRANT USAGE ON *.* TO 'scott'@'localhost'",
          "GRANT EXECUTE ON FUNCTION `#{TEST_DATABASE}`.`foo` TO 'scott'@'localhost'"
        ]
      end
    end
  end

  context 'when create user with procedure' do
    subject { client }

    it do
      create_procedures(:foo) do
        result = apply(subject) {
          <<-RUBY
  user 'scott', 'localhost' do
    on '*.*' do
      grant 'USAGE'
    end

    on 'PROCEDURE #{TEST_DATABASE}.foo' do
      grant 'EXECUTE'
    end
  end
          RUBY
        }

        expect(result).to be_truthy

        expect(show_grants).to match_array [
          "GRANT USAGE ON *.* TO 'scott'@'localhost'",
          "GRANT EXECUTE ON PROCEDURE `#{TEST_DATABASE}`.`foo` TO 'scott'@'localhost'"
        ]
      end
    end
  end
end
