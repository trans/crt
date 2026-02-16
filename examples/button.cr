require "../src/crt"

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Status
  status = CRT::Label.new(screen, x: 2, y: 1, width: 30, height: 1, text: "")

  # Widget
  button = CRT::Button.new(screen, x: 2, y: 3, text: "Click Me") do
    status.text = "Button clicked!"
  end
  screen.focus(button)

  # Quit hint
  CRT::Label.new(screen, x: 2, y: 5, text: "Enter/Space to activate | Ctrl+C to quit")

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
