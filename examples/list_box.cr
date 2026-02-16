require "../src/crt"

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Widget
  colors = ["Red", "Orange", "Yellow", "Green", "Blue", "Indigo", "Violet", "Black"]
  lb = CRT::ListBox.new(screen, x: 2, y: 1, items: colors, height: 7)
  screen.focus(lb)

  # Quit hint
  CRT::Label.new(screen, x: 2, y: 9, text: "Up/Down/Home/End to navigate | Ctrl+C to quit")

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
