# Rails

The step 1 program as a Rails application with acemq-amqp-rails: one connection
configured from `config.acemq`, a controller that publishes with
`AceMQ::Rails.publish`, and a consumer class.

Consumers never run inside the web server; in production they are a process of
their own, `bundle exec acemq-consumer`. To be one file that ends with a status,
`main.rb` boots the application, starts that same runner in a thread, posts
three orders to the controller through Rack, waits for the consumer and drains.
