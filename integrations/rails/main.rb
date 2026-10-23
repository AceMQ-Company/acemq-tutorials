# frozen_string_literal: true

# Step 8 for Ruby: the same publish and consume as step 1, written the way a
# Rails application writes it.
#
# acemq-amqp-rails gives the application one connection, configured from
# config.acemq (or config/acemq.yml); a controller publishes with
# AceMQ::Rails.publish; a consumer is a class. Consumers never run inside the
# web server: in production they are a process of their own,
# `bundle exec acemq-consumer`. To be one file that ends with a status, this
# script boots the application, starts that same runner in a thread, sends three
# requests to the controller through Rack, waits for the consumer, and drains.

require "bundler/setup"
require "rails"
require "action_controller/railtie"
require "acemq-amqp-rails"

class TutorialApp < Rails::Application
  config.root = __dir__
  config.eager_load = false
  config.enable_reloading = false
  config.secret_key_base = "acemq-tutorials-step-8"
  config.hosts.clear
  config.logger = ActiveSupport::Logger.new($stdout)
  config.log_level = :warn

  # What a real application writes in config/acemq.yml. The tutorial image sets
  # ACEMQ_URL.
  config.acemq.url = ENV.fetch("ACEMQ_URL", "amqp://guest:guest@localhost:5672")
  config.acemq.client_name = "tutorial-orders"
  config.acemq.topology = {
    "exchanges" => [{ "name" => "tutorial.orders", "type" => "topic" }],
    "queues" => [{ "name" => "tutorial.orders.new" }],
    "bindings" => [{ "queue" => "tutorial.orders.new", "exchange" => "tutorial.orders",
                     "routing_key" => "order.created" }]
  }

  routes.append { post "/orders/:id", to: "orders#create" }
end

# app/controllers/orders_controller.rb
class OrdersController < ActionController::API
  def create
    order = { "id" => params[:id], "quantity" => params[:quantity].to_i }
    # Returns once the broker has confirmed it: confirms are on by default.
    AceMQ::Rails.publish(order, to: "order.created", exchange: "tutorial.orders",
                                type: "order.placed.v1")
    render json: order, status: :accepted
  end
end

RECEIVED = Thread::Queue.new

# app/consumers/orders_consumer.rb
class OrdersConsumer < AceMQ::Rails::Consumer
  queue "tutorial.orders.new"

  def call(message)
    order = message.payload
    puts "received #{order["id"]} for #{order["quantity"]} unit(s)"
    RECEIVED << order
    accept
  end
end

TutorialApp.initialize!

# `bundle exec acemq-consumer`, in a thread: applies the topology, subscribes.
runner = AceMQ::Rails::Runner.new
runner.start([OrdersConsumer])

web = Rack::MockRequest.new(Rails.application)
(1..3).each do |n|
  response = web.post("/orders/o-#{n}?quantity=#{n}")
  abort "POST /orders/o-#{n} answered #{response.status}: #{response.body}" unless response.status == 202
  puts "published o-#{n}"
end

deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 15
got = 0
while got < 3
  left = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
  break if left <= 0 || RECEIVED.pop(timeout: left).nil?

  got += 1
end

# What SIGTERM does to `acemq-consumer`: stop taking deliveries, finish the
# handlers in flight, close the connection.
drained = runner.drain
if got < 3
  warn "the consumer received #{got} of three orders within 15s"
  exit 1
end
abort "the drain did not finish in time" unless drained
puts "three published, three received, drained"
