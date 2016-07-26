require 'serialport'
require 'byebug'

def read
  ser = SerialPort.new("/dev/ttyUSB0", 115200, 8, 1, SerialPort::NONE)
  ser.read_timeout= 1000
  distance = nil
  while distance.nil? do
    sleep(0.02)
    line = ser.readline("\r")
    distance = /(\d*[.]\d*)(?= m)/.match(line)
    return distance[0].to_f if distance
    puts "try again"
  end
end

while true do
	puts read
end
