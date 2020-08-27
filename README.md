# nfcreader-tf

A simple helper program that accesses a
[Tinkerforge NFC sensor](https://www.tinkerforge.com/doc/Hardware/Bricklets/NFC.html)
and prints out recognized NFC tags on STDOUT.

## Installation

Clone the repository, call `shards build` and run `bin/nfcreader-tf`.
For frequent use, you may consider copying/linking to the binary to/from a place
in your `PATH` like `/usr/local/bin`.

## Usage

You can invoke `nfcreader-tf` with the `--ip` and `--port` options to define
where it should try to connect to a Tinkerforge staple (aka the "controller"
Master/HAT/... brick). If you don't provide these options, `localhost:4223`
is assumed as default.

There is also a `--uuid` option that allows you to specify the exact NFC Bricklet
which should be used. Providing this option is only necessary in case
there are multiple NFC Bricklets attached to the connected staple.

By default, `nfcreader-tf` starts scanning for NFC tags upon invocation. You can
alter this behavior by passing the `--off` option; in this case, you need to turn
on/off the sensor manually by entering the "command" `on` / `off` on STDIN.
This option is particularly suited for use as a subprocess (e.g. from a script),
because you can keep `nfcreader-tf` running as a "daemon" with STDIN and STDOUT
piped to the controlling process and start/stop scanning for tags at random.

Whenever `nfcreader-tf` has detected an NFC tag, it will print the raw tag ID
to STDOUT. To avoid multiple issues of the same tag ID, the last found tag ID
is "cached" internally; so don't be surprised if scanning the same tag multiple
times doesn't work! (In future versions, an option might be added to modify
this behavior, e.g. by setting a caching time or switching it off entirely.)

You can exit `nfcreader-tf` by entering `exit` on its "command line" or
by simply pressing Ctrl+C.

## Contributing

1. Fork it (<https://github.com/feritarou/nfcreader-tf/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Felix Schwarz](https://github.com/feritarou) - creator and maintainer
