require "../src/crt"

CODE = <<-CRYSTAL
  CRT::Checkbox.new(screen, x: 2, y: 5,
    text: "Enable notifications",
    checked: true)
  CRYSTAL

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Code
  code_style = CRT::Style.new(fg: CRT::Color.rgb(180, 180, 180))
  CRT::Label.new(screen, x: 2, y: 1, text: CODE, style: code_style,
    border: CRT::Border::Rounded, pad: 1)

  # Widget
  cb = CRT::Checkbox.new(screen, x: 2, y: 5, text: "Enable notifications", checked: true)
  screen.focus(cb)

  # Quit hint
  hint_style = CRT::Style.new(dim: true)
  CRT::Label.new(screen, x: 2, y: 8, text: "Space/Enter to toggle | Ctrl+C to quit",
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
