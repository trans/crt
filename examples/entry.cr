require "../src/crt"

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Widget
  entry = CRT::Entry.new(screen, x: 2, y: 1, width: 30, text: "edit me")
  screen.focus(entry)

  # Quit hint
  CRT::Label.new(screen, x: 2, y: 4, text: "Type to edit | Ctrl+C to quit")

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
