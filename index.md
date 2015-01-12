---
layout: default
---

# Gratan

Gratan is a tool to manage MySQL permissions.

It defines the state of MySQL permissions using Ruby DSL, and updates permissions according to DSL.

[![Gem Version](https://badge.fury.io/rb/gratan.svg)](http://badge.fury.io/rb/gratan)
[![Build Status](https://travis-ci.org/winebarrel/gratan.svg?branch=master)](https://travis-ci.org/winebarrel/gratan)
[![Coverage Status](https://img.shields.io/coveralls/winebarrel/gratan.svg)](https://coveralls.io/r/winebarrel/gratan?branch=master)

## Installation

Add this line to your application's Gemfile:

{% highlight ruby %}
gem 'gratan'
{% endhighlight %}


And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gratan

## Usage

{% highlight sh %}
gratan -e -o Grantfile
vi Grantfile
gratan -a --dry-run
gratan -a
{% endhighlight %}

## Help

{% highlight sh %}
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
        --no-color
        --debug
        --auto-identify OUTPUT
        --csv-identify CSV
    -h, --help
{% endhighlight %}

## Grantfile example

{% highlight ruby %}
require 'other/grantfile'

user "scott", "%" do
  on "*.*" do
    grant "USAGE"
  end

  on "test.*", expired: '2014/10/08' do
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
{% endhighlight %}

## Similar tools
* [Codenize.tools](http://http://codenize.tools/)

## What does "Gratan" mean?

[![](http://i.gyazo.com/c37d934ba0a61f760603ce4c56401e60.png)](https://www.google.com/search?q=gratin&tbm=isch)
