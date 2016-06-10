current_valuation = 0
current_karma = 0

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
    @average_processing_estimator = AverageProcessingEstimator.new(30)
    @size_of_queue = 10
    @last_queue_exit_timestamp = Time.now
  end

  def queue_size_update(size)

  end

  def queue_exit_event

  end

  def to_s
    estimate_time_text
  end

  def estimate_time_text
    seconds_to_units(estimate_time_seconds)
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

estimator = QueueWaitEstimator.new


SCHEDULER.every '1s' do
  last_valuation = current_valuation
  last_karma     = current_karma
  current_valuation = rand(100)
  current_karma     = rand(200000)



  send_event('welcome', { text: "#{estimator}"})
  #send_event('valuation', { current: current_valuation, last: last_valuation })
  #send_event('karma', { current: current_karma, last: last_karma })
  #send_event('synergy',   { value: rand(100) })
end
