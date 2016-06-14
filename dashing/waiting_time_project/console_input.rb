require 'io/console'
require 'yaml'

QUEUE_FILE_NAME = 'queue_status.yaml'

@customers = 0

puts 'q - quit, n - customer entry, m - customer exit'

def update_file(customers,timestamp = nil)
  queue_status = YAML::load_file(QUEUE_FILE_NAME) rescue d = {}
  queue_status['queue_size'] = customers
  queue_status['last_exit_timestamp'] = timestamp.to_s unless timestamp.nil?
  File.open(QUEUE_FILE_NAME, 'w') {|f| f.write queue_status.to_yaml } #Store
end

def customer_entry
  @customers = @customers + 1
  update_file(@customers,nil)
  puts "Customer Entry Event - #{@customers} in queue"
end

def customer_exit
  if @customers > 0 then
    @customers = @customers - 1
    update_file(@customers,Time.now)
    puts "Customer Exit Event - #{@customers} in queue"
  end
end

loop do
  character = STDIN.getch
  exit if character == 'q'
  customer_entry if character == 'n'
  customer_exit  if character == 'm'
end
