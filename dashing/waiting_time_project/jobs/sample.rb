require 'yaml'
require 'serialport'

class RangeFinderQueueSize
  def initialize(length_per_unit:, zero_point_distance:)
    @length_per_unit = length_per_unit
    @zero_point_distance = zero_point_distance

    connect_to_device
  end

  def size
    length_of_units_in_queue = @zero_point_distance - read_range
    length_of_units_in_queue = 0 if length_of_units_in_queue < 0
    (length_of_units_in_queue / @length_per_unit).floor
  end

  private

  def connect_to_device
    @port = find_and_connect_to_port
  end

  def find_and_connect_to_port
    ser = nil
    portname = ''
    (0..9).to_a.each do | number |
      portname = "/dev/ttyUSB#{number}"
      if ser.nil? then
        ser = SerialPort.new(portname, 115200, 8, 1, SerialPort::NONE) rescue nil
      else
        break
      end
    end

    $stderr.puts 'No serial port to bind to' if ser.nil?
    return 0 if ser.nil?
    $stderr.puts "Connected to #{portname}"
    ser.read_timeout=200
    ser
  end


  def read_range
    distance = nil
    while distance.nil? do
      sleep(0.02)
      line = @port.readline("\r")
      $stderr.puts line
      distance = /(\d*[.]\d*)(?= m)/.match(line)
      return distance[0].to_f if distance
    end
  end
end

QUEUE_FILE_NAME = 'queue_status.yaml'


class AverageProcessingEstimator
  def initialize(initial_estimate)
    @initial_estimate = initial_estimate
  end
  def estimate
    @initial_estimate
  end
  def queue_exit_event(number_in_queue)

  end
end

@queue_size = RangeFinderQueueSize.new(length_per_unit: 1, zero_point_distance: 6)

class QueueWaitEstimator
  def initialize(queue_size)
    @queue_size = queue_size
    @average_time_per_unit = 30
    read_queue_status_file
    @average_processing_estimator = AverageProcessingEstimator.new(30)
    @previous_size_of_queue = 0
  end

  def read_queue_status_file
    queue_status = YAML::load_file(QUEUE_FILE_NAME) rescue d = {}
    @last_queue_exit_timestamp = Time.parse(queue_status['last_exit_timestamp']) rescue Time.now
    @size_of_queue = queue_status['queue_size'] rescue 0
  end

  def to_s
    #read_queue_status_file
    current_size = @queue_size.size
    @last_queue_exit_timestamp = Time.now if @previous_size_of_queue != current_size
    estimate_time_seconds = (current_size * @average_time_per_unit) + estimate_time_remaining_with_current_unit
    @previous_size_of_queue = current_size

    "#{seconds_to_units(estimate_time_seconds)}"
  end

  private

  def estimate_time_remaining_with_current_unit
    remaining = @average_time_per_unit - (Time.now - @last_queue_exit_timestamp).to_i
    remaining = 0 if remaining < 0
    remaining
  end

  def seconds_to_units(total_seconds)
    seconds = total_seconds % 60
    minutes = ((total_seconds-seconds) % (60*60)) / 60

    "%d" % minutes + ':' + "%.2d" % seconds
  end
end


queue_status = YAML::load_file(QUEUE_FILE_NAME) rescue d = {}
queue_status['queue_size'] = 0
queue_status['last_exit_timestamp'] = Time.now.to_s
File.open(QUEUE_FILE_NAME, 'w') {|f| f.write queue_status.to_yaml } #Store

estimator = QueueWaitEstimator.new(@queue_size)




SCHEDULER.every '0.5s' do
  send_event('welcome', { text: "#{estimator}"})
end
