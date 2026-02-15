require "../src/crt"

CODE = <<-CRYSTAL
  CRT::ListBox.new(screen, x: 2, y: 5,
    items: colors, height: 7)
  CRYSTAL

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Code
  code_style = CRT::Style.new(fg: CRT::Color.rgb(180, 180, 180))
  CRT::Label.new(screen, x: 2, y: 1, text: CODE, style: code_style,
    border: CRT::Border::Rounded, pad: 1)

  # Widget
  colors = ["Red", "Orange", "Yellow", "Green", "Blue", "Indigo", "Violet", "Black"]
  lb = CRT::ListBox.new(screen, x: 2, y: 5, items: colors, height: 7)
  screen.focus(lb)

  # Quit hint
  hint_style = CRT::Style.new(dim: true)
  CRT::Label.new(screen, x: 2, y: 13, text: "Up/Down/Home/End to navigate | Ctrl+C to quit",
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
