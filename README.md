# Gratan

Gratan is a tool to manage MySQL permissions.

It defines the state of MySQL permissions using Ruby DSL, and updates permissions according to DSL.

[![Gem Version](https://badge.fury.io/rb/gratan.svg)](http://badge.fury.io/rb/gratan)
[![Build Status](https://travis-ci.org/winebarrel/gratan.svg?branch=master)](https://travis-ci.org/winebarrel/gratan)
[![Coverage Status](https://coveralls.io/repos/winebarrel/gratan/badge.svg?branch=master)](https://coveralls.io/r/winebarrel/gratan?branch=master)

## Notice

* `>= 0.3.0`
  * Support template

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gratan'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gratan

## Usage

```sh
gratan -e -o Grantfile
vi Grantfile
gratan -a --dry-run
gratan -a
```

## Help

```sh
Usage: gratan [options]
        --host HOST
        --port PORT
        --socket SOCKET
        --username USERNAME
        --password PASSWORD
        --database DATABASE
    -a, --apply
    -f, --file FILE
        --dry-run
    -e, --export
        --with-identifier
        --split
        --chunk-by-user
    -o, --output FILE
        --ignore-user REGEXP
        --target-user REGEXP
        --ignore-object REGEXP
        --enable-expired
        --ignore-not-exist
        --skip-disable-log-bin
        --no-color
        --debug
        --auto-identify OUTPUT
        --csv-identify CSV
        --mysql2-options JSON
    -h, --help
```

A default connection to a database can be established by setting the following environment variables:  
- `GRATAN_DB_HOST`: database host
- `GRATAN_DB_PORT`: database port
- `GRATAN_DB_SOCKET`: database socket
- `GRATAN_DB_DATABASE`: database database name
- `GRATAN_DB_USER`: database user
- `GRATAN_DB_PASSWORD`: database password

## Grantfile example

```ruby
require 'other/grantfile'

user "scott", "%" do
  on "*.*" do
    grant "USAGE"
  end

  on "test.*", expired: '2014/10/08', identified: "PASSWORD '*ABCDEF'" do
    grant "SELECT"
    grant "INSERT"
  end

  on /^foo\.prefix_/ do
    grant "SELECT"
    grant "INSERT"
  end
end

user "scott", ["localhost", "192.168.%"], expired: '2014/10/10' do
  on "*.*", with: 'GRANT OPTION' do
    grant "ALL PRIVILEGES"
  end
end
```

### Use template

```ruby
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
```

## Similar tools
* [Codenize.tools](http://codenize.tools/)

## What does "Gratan" mean?

[![](http://i.gyazo.com/c37d934ba0a61f760603ce4c56401e60.png)](https://www.google.com/search?q=gratin&tbm=isch)
