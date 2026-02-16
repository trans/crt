require "../src/crt"

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Widget
  bar = CRT::ProgressBar.new(screen, x: 2, y: 1, width: 30)

  # Quit hint
  CRT::Label.new(screen, x: 2, y: 4, text: "Ctrl+C to quit")

  screen.run(fps: 30) do
    bar.value = (bar.value + 0.005) % 1.0
    screen.each_event do |event|
      case event
      when CRT::Key
        screen.quit if event.ctrl? && event.char == "c"
      end
    end
  end
end
