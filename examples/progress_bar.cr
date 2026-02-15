require "../src/crt"

CODE = <<-CRYSTAL
  CRT::ProgressBar.new(screen, x: 2, y: 5,
    width: 30, value: 0.4)
  CRYSTAL

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Code
  code_style = CRT::Style.new(fg: CRT::Color.rgb(180, 180, 180))
  CRT::Label.new(screen, x: 2, y: 1, text: CODE, style: code_style,
    border: CRT::Border::Rounded, pad: 1)

  # Widget
  bar = CRT::ProgressBar.new(screen, x: 2, y: 5, width: 30, value: 0.4)

  # Quit hint
  hint_style = CRT::Style.new(dim: true)
  CRT::Label.new(screen, x: 2, y: 8, text: "Ctrl+C to quit", style: hint_style)

  screen.run(fps: 30) do
    if event = screen.poll_event
      case event
      when CRT::Key
        screen.quit if event.ctrl? && event.char == "c"
      end
    end
  end
end
