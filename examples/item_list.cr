require "../src/crt"

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Status
  status = CRT::Label.new(screen, x: 2, y: 1, width: 30, height: 1, text: "Selected: Red")

  # Widget
  items = ["Red", "Green", "Blue", "Yellow", "Cyan", "Magenta"]
  il = CRT::ItemList.new(screen, x: 2, y: 3, items: items)
  il.on_change = ->(i : Int32) { status.text = "Selected: #{items[i]}"; nil }
  screen.focus(il)

  # Exit button
  CRT::Button.new(screen, x: 2, y: 5, text: "Exit") { screen.quit }

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
