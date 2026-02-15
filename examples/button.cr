require "../src/crt"

CODE = <<-CRYSTAL
  CRT::Button.new(screen, x: 2, y: 8,
    text: "Click Me") do
    status.text = "Button clicked!"
  end
  CRYSTAL

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Code
  code_style = CRT::Style.new(fg: CRT::Color.rgb(180, 180, 180))
  CRT::Label.new(screen, x: 2, y: 1, text: CODE, style: code_style,
    border: CRT::Border::Rounded, pad: 1)

  # Status
  status = CRT::Label.new(screen, x: 2, y: 12, width: 30, height: 1, text: "")

  # Widget
  button = CRT::Button.new(screen, x: 2, y: 8, text: "Click Me") do
    status.text = "Button clicked!"
  end
  screen.focus(button)

  # Quit hint
  hint_style = CRT::Style.new(dim: true)
  CRT::Label.new(screen, x: 2, y: 14, text: "Enter/Space to activate | Ctrl+C to quit",
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
