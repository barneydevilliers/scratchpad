require 'yaml'
require 'serialport'

def read_range
  names_to_try = ["/dev/ttyUSB0","/dev/ttyUSB1"]

  ser = nil
  names_to_try.each do | name |
    puts "trying #{name}"
    if ser.nil? then
      ser = SerialPort.new(name, 115200, 8, 1, SerialPort::NONE) rescue nil
    end
  end

  if ser
    ser.read_timeout= 1000
    distance = nil
    while distance.nil? do
      sleep(0.02)
      line = ser.readline("\r")
      distance = /(\d*[.]\d*)(?= m)/.match(line)
      return distance[0].to_f if distance
    end
  else
    return -1
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
    read_queue_status_file
    @average_processing_estimator = AverageProcessingEstimator.new(30)

  end

  def queue_size_update(size)

  end

  def queue_exit_event

  end

  def read_queue_status_file
    queue_status = YAML::load_file(QUEUE_FILE_NAME) rescue d = {}
    @last_queue_exit_timestamp = Time.parse(queue_status['last_exit_timestamp']) rescue Time.now
    @size_of_queue = queue_status['queue_size'] rescue 0
  end

  def to_s
    read_queue_status_file
    estimate_time_text
  end

  def estimate_time_text
    "range #{read_range.to_s} #{seconds_to_units(estimate_time_seconds)}"
  end

  def estimate_time_seconds
    queue_wait_time + estimate_time_remaining_with_current_processing
  end

  private

  def estimate_time_remaining_with_current_processing
    remaining = @average_processing_estimator.estimate - (Time.now - @last_queue_exit_timestamp).to_i
    remaining = 0 if remaining < 0
    remaining
  end

  def queue_wait_time
    @average_processing_estimator.estimate * @size_of_queue
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




SCHEDULER.every '1s' do
  send_event('welcome', { text: "#{estimator}"})
end
