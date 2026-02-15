require "../src/crt"

CODE = <<-CRYSTAL
  CRT::ScrollBar.new(screen, x: 2, y: 5,
    length: 10, thumb_size: 0.3)
  CRYSTAL

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Code
  code_style = CRT::Style.new(fg: CRT::Color.rgb(180, 180, 180))
  CRT::Label.new(screen, x: 2, y: 1, text: CODE, style: code_style,
    border: CRT::Border::Rounded, pad: 1)

  # Vertical scrollbar
  vsb = CRT::ScrollBar.new(screen, x: 2, y: 5, length: 10, thumb_size: 0.3)

  # Horizontal scrollbar
  hsb = CRT::ScrollBar.new(screen, x: 5, y: 5,
    orientation: CRT::Orientation::Horizontal, length: 20, thumb_size: 0.3)

  # Value label
  val_label = CRT::Label.new(screen, x: 5, y: 7, width: 20, height: 1, text: "V: 0.0  H: 0.0")

  vsb.on_change = ->(v : Float64) { val_label.text = "V: #{v.round(2)}  H: #{hsb.value.round(2)}"; nil }
  hsb.on_change = ->(v : Float64) { val_label.text = "V: #{vsb.value.round(2)}  H: #{v.round(2)}"; nil }

  screen.focus(vsb)

  # Quit hint
  hint_style = CRT::Style.new(dim: true)
  CRT::Label.new(screen, x: 2, y: 16, text: "Up/Down to scroll | Tab to switch | Ctrl+C to quit",
    style: hint_style)

  screen.run(fps: 30) do
    if event = screen.poll_event
      case event
      when CRT::Key
        screen.quit if event.ctrl? && event.char == "c"
      end
      screen.dispatch(event)
    end
  end
end
