require "../src/crt"

CODE = <<-CRYSTAL
  CRT::Label.new(screen, x: 2, y: 6,
    text: "Hello, World!",
    style: CRT::Style.new(bold: true,
      fg: CRT::Color.rgb(120, 200, 255)))
  CRYSTAL

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Code
  code_style = CRT::Style.new(fg: CRT::Color.rgb(180, 180, 180))
  CRT::Label.new(screen, x: 2, y: 1, text: CODE, style: code_style,
    border: CRT::Border::Rounded, pad: 1)

  # Widget
  CRT::Label.new(screen, x: 2, y: 6,
    text: "Hello, World!",
    style: CRT::Style.new(bold: true,
      fg: CRT::Color.rgb(120, 200, 255)))

  # Quit hint
  hint_style = CRT::Style.new(dim: true)
  CRT::Label.new(screen, x: 2, y: 11, text: "Ctrl+C to quit", style: hint_style)

  screen.run(fps: 30) do
    if event = screen.poll_event
      case event
      when CRT::Key
        screen.quit if event.ctrl? && event.char == "c"
      end
    end
  end
end
