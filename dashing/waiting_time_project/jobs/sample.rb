require 'yaml'
require 'serialport'

class RangeFinderQueueSize
  def initialize(length_per_unit:, zero_point_distance:)
    @length_per_unit = length_per_unit
    @zero_point_distance = zero_point_distance
  end

  def size
    length_of_units_in_queue = @zero_point_distance - read_range
    length_of_units_in_queue = 0 if length_of_units_in_queue < 0
    (length_of_units_in_queue / @length_per_unit).floor
  end

  private

  def read_range
    ser = nil
    (0..9).to_a.each do | number |
      portname = "/dev/ttyUSB#{number}"
      if ser.nil? then
        ser = SerialPort.new(portname, 115200, 8, 1, SerialPort::NONE) rescue nil
      else
        break
      end
    end

    raise RuntimeError 'No serial port to bind to' if ser.nil?

    ser.read_timeout=200
    distance = nil
    while distance.nil? do
      sleep(0.02)
      line = ser.readline("\r")
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

class QueueWaitEstimator
  def initialize
    @average_time_per_unit = 30
    read_queue_status_file
    @average_processing_estimator = AverageProcessingEstimator.new(30)

  end

  def read_queue_status_file
    queue_status = YAML::load_file(QUEUE_FILE_NAME) rescue d = {}
    @last_queue_exit_timestamp = Time.parse(queue_status['last_exit_timestamp']) rescue Time.now
    @size_of_queue = queue_status['queue_size'] rescue 0
  end

  def to_s
    #read_queue_status_file
    previous_size_of_queue = @size_of_queue.size
    @size_of_queue = RangeFinderQueueSize.new(length_per_unit: 1, zero_point_distance: 6)
    @last_queue_exit_timestamp = Time.now if previous_size_of_queue != @size_of_queue.size

    estimate_time_seconds = (@size_of_queue.size * @average_time_per_unit) + estimate_time_remaining_with_current_unit

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

estimator = QueueWaitEstimator.new




SCHEDULER.every '0.5s' do
  send_event('welcome', { text: "#{estimator}"})
end
