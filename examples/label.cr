require "../src/crt"

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Widget
  CRT::Label.new(screen, x: 2, y: 1,
    text: "Hello, World!",
    border: CRT::Border::Rounded, pad: 1)

  # Quit hint
  CRT::Label.new(screen, x: 2, y: 6, text: "Ctrl+C to quit")

  screen.run(fps: 30) do
    screen.each_event do |event|
      case event
      when CRT::Key
        screen.quit if event.ctrl? && event.char == "c"
      end
    end
  end
end
