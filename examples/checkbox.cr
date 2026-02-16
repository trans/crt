require "../src/crt"

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Widget
  cb = CRT::Checkbox.new(screen, x: 2, y: 1, text: "Enable notifications", checked: true)
  screen.focus(cb)

  # Quit hint
  CRT::Label.new(screen, x: 2, y: 3, text: "Space/Enter to toggle | Ctrl+C to quit")

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
