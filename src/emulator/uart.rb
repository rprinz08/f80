require 'zemu'

class Uart < Zemu::Config::SerialPort
    def initialize
        super
    end

	def io_read(port)
		if port == in_port
			return @buffer_rx.shift()
		elsif port == ready_port
			if @buffer_rx.empty?
				return 0x10
			else
				return 0x11
			end
		end

		nil
	end
end

