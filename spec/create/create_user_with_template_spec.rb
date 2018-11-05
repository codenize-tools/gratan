describe 'Gratan::Client#apply' do
  context 'when create user with template' do
    subject { client }

    it do
      result = apply(subject) {
        <<-RUBY
template 'all db template' do
  on '*.*' do
    grant 'SELECT'
  end
end

template 'test db template' do
  grant context.default

  context.extra.each do |priv|
    grant priv
  end
end

user 'scott', 'localhost', identified: 'tiger' do
  include_template 'all db template'

  on 'test.*' do
    context.default = 'SELECT'
    include_template 'test db template', extra: ['INSERT', 'UPDATE']
  end
end
        RUBY
      }

      expect(result).to be_truthy

      expect(show_grants).to match_array [
        "GRANT SELECT ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40'",
        "GRANT SELECT, INSERT, UPDATE ON `test`.* TO 'scott'@'localhost'",
      ].normalize
    end
  end
end
