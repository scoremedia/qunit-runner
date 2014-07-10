# Qunit::Runner

A ruby command line runner for Qunit tests using PhantomJS

## Installation

Add this line to your application's Gemfile:

    gem 'qunit-runner'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install qunit-runner

## Usage

```
qunit-runner test \[--timeout=milleseconds\] URL
```

This will run a test suite located at the provided URL, giving an appropriate
exit status and displaying test run progress and status.

## API Usage

You can invoke the test runner from inside your application using the
`Qunit::Runner` class. Initialize the runner with the test URL, and then run the
engine, optionally specifying a timeout.

```
url = "http://localhost:3000"
Qunit::Runner.new(url).run
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
