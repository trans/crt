require "spec"
require "../src/crt"

# Concrete widget for testing the abstract base class.
class TestWidget < CRT::Widget
  property draw_count = 0

  def draw(canvas : CRT::Ansi::Canvas) : Nil
    @draw_count += 1
  end
end

# Focusable widget for testing focus management.
class FocusableWidget < CRT::Widget
  property draw_count = 0
  property last_event : CRT::Ansi::Event? = nil

  def initialize(screen : CRT::Screen, *, x : Int32, y : Int32,
                 width : Int32, height : Int32,
                 style : CRT::Ansi::Style = CRT::Ansi::Style.default,
                 border : CRT::Ansi::Border? = nil,
                 shadow : Bool = false,
                 visible : Bool = true)
    super(screen, x: x, y: y, width: width, height: height,
          style: style, border: border, shadow: shadow,
          visible: visible, focusable: true)
  end

  def draw(canvas : CRT::Ansi::Canvas) : Nil
    @draw_count += 1
  end

  def handle_event(event : CRT::Ansi::Event) : Bool
    @last_event = event
    true
  end
end

def test_screen : CRT::Screen
  CRT::Screen.new(IO::Memory.new, alt_screen: false, raw_mode: false, hide_cursor: false)
end
