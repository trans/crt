require "../src/crt"

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Vertical slider
  vsb = CRT::Slider.new(screen, x: 2, y: 1, length: 10, thumb_size: 0.3)

  # Horizontal slider
  hsb = CRT::Slider.new(screen, x: 5, y: 1,
    orientation: CRT::Orientation::Horizontal, length: 20, thumb_size: 0.3)

  # Value label
  val_label = CRT::Label.new(screen, x: 5, y: 3, width: 20, height: 1, text: "V: 0.0  H: 0.0")

  vsb.on_change = ->(v : Float64) { val_label.text = "V: #{v.round(2)}  H: #{hsb.value.round(2)}"; nil }
  hsb.on_change = ->(v : Float64) { val_label.text = "V: #{vsb.value.round(2)}  H: #{v.round(2)}"; nil }

  screen.focus(vsb)

  # Quit hint
  CRT::Label.new(screen, x: 2, y: 12, text: "Up/Down to scroll | Tab to switch | Ctrl+C to quit")

  screen.run(fps: 30) do
    screen.each_event do |event|
      case event
      when CRT::Key
        screen.quit if event.ctrl? && event.char == "c"
      end
      screen.dispatch(event)
    end
  end
end
