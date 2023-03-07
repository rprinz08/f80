require 'zemu'

# Register mapped to an IO port.
class Register < Zemu::Config::BusDevice

    def initialize
        super

        @reg_state = 0
    end

    def params
        super + %w(io_port)
    end

    def io_write(port, value)
        # Port decode logic is local to each
        # device. This allows multiple
        # devices to listen on the same port.
        if port == io_port
            @reg_state = value
        end
    end

    def io_read(port)
        if port == io_port
            return @reg_state
        end

        # Read operations return nil
        # if the port is not applicable
        # - e.g. does not correspond to
        # this device.
        nil
    end

    def get_reg_state
        @reg_state
    end

    def set_reg_state(value)
        @reg_state = value
    end

end

