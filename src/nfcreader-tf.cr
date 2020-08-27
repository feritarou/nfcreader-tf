require "log"
require "option_parser"

{% unless flag? :docsgen %}
require "tinkerforge"
{% end %}

# `nfcreader-tf` is a simple helper program that accesses a
# [Tinkerforge NFC sensor](https://www.tinkerforge.com/doc/Hardware/Bricklets/NFC.html)
# and prints out recognized NFC tags on STDOUT.
#
# ## Usage
# You can invoke `nfcreader-tf` with the `--ip` and `--port` options to define
# where it should try to connect to a Tinkerforge staple (aka the "controller"
# Master/HAT/... brick). If you don't provide these options, `localhost:4223`
# is assumed as default.
#
# There is also a `--uuid` option that allows you to specify the exact NFC Bricklet
# which should be used. Providing this option is only necessary in case
# there are multiple NFC Bricklets attached to the connected staple.
#
# By default, `nfcreader-tf` starts scanning for NFC tags upon invocation. You can
# alter this behavior by passing the `--off` option; in this case, you need to turn
# on/off the sensor manually by entering the "command" `on` / `off` on STDIN.
# This option is particularly suited for use as a subprocess (e.g. from a script),
# because you can keep `nfcreader-tf` running as a "daemon" with STDIN and STDOUT
# piped to the controlling process and start/stop scanning for tags at random.
#
# Whenever `nfcreader-tf` has detected an NFC tag, it will print the raw tag ID
# to STDOUT. To avoid multiple issues of the same tag ID, the last found tag ID
# is "cached" internally; so don't be surprised if scanning the same tag multiple
# times doesn't work! (In future versions, an option might be added to modify
# this behavior, e.g. by setting a caching time or switching it off entirely.)
#
# You can exit `nfcreader-tf` by entering `exit` on its "command line" or
# by simply pressing Ctrl+C.
module NfcReaderTf
  extend self

  # =======================================================================================
  # Constants
  # =======================================================================================

  # :nodoc:
  Log = ::Log.for("nfcreader-tf")

  # =======================================================================================
  # Class variables
  # =======================================================================================

  @@ip = "localhost"
  @@port = 4223
  @@uuid = ""

  @@auto_scan = true
  @@last_tag = ""

  # =======================================================================================
  # Methods
  # =======================================================================================

  # The main thread of execution.
  def run
    ::Log.setup_from_env
    parse_cmd_line_options

    staple = TF::Staple.new
    staple.connect @@ip, @@port, give_feedback: false
    if !staple.connected?
      STDERR.puts "Could not connect to #{@@ip}:#{@@port}! Aborting."
      exit 1
    end

    sensor = @@uuid.empty? ? staple.nfc : staple[@@uuid]?

    case sensor
    when Nil
      STDERR.puts @@uuid.empty? ? "No NFC sensor found in the staple! Aborting."
                               : "No NFC sensor with UUID #{@@uuid} found! Aborting."
      exit 1

    when TF::NfcBricklet
      sensor.tag_id = ""
      sensor.mode = :reader if @@auto_scan

      closing = false

      # Register signal handler for Ctrl+C
      Signal::INT.trap do
        closing = true
        sensor.as(TF::NfcBricklet).mode = :off
        Fiber.yield
        exit 0
      end

      spawn do
        until closing
          tag = sensor.as(TF::NfcBricklet).tag_id
          if !tag.empty? && tag != @@last_tag
            @@last_tag = tag
            puts tag
          end
          sleep 50.milliseconds
        end
      end

      until closing
        pattern = gets
        if pattern
          case pattern.downcase
          when "off"
            sensor.as(TF::NfcBricklet).mode = :off
          when "on"
            sensor.as(TF::NfcBricklet).mode = :reader
          when "exit"
            closing = true
            sensor.as(TF::NfcBricklet).mode = :off
            exit 0
          end
        end
        Fiber.yield
      end
    end
  end

  # =======================================================================================
  # Helper methods
  # =======================================================================================

  private def parse_cmd_line_options
    OptionParser.parse do |p|
      p.banner = "Usage: nfcreader-tf [args]"

      p.on "-h", "--help",
           "Shows this help" do
        puts p
        exit 0
      end

      p.on "--ip=ADDRESS",
           "Specifies the IP address to connect to (default: localhost)" do |addr|
        @@ip = addr
      end

      p.on "--port=PORT",
           "Specifies the port to connect to (default: 4223)" do |port|
        @@port = port.to_i32
      end

      p.on "--uuid=UUID",
           "Specifies the UUID of a particular NFC Bricklet to use" do |uuid|
        @@uuid = uuid
      end

      p.on "--off",
           "Do not switch on the NFC sensor upon invocation" do
        @@auto_scan = false
      end

      p.invalid_option do |flag|
        STDERR.puts "Invalid option #{flag}."
        STDERR.puts p
        exit 1
      end
    end
  end

end

NfcReaderTf.run
