require "crt-ansi"

module CRT
  VERSION = "0.1.0"

  alias Style  = Ansi::Style
  alias Color  = Ansi::Color
  alias Border = Ansi::Border
  alias Key    = Ansi::Key
  alias Mouse  = Ansi::Mouse
  alias Event  = Ansi::Event
end

require "./crt/widget"
require "./crt/screen"
require "./crt/components/label"
