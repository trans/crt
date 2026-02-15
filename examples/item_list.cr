require "../src/crt"

CODE = <<-CRYSTAL
  CRT::ItemList.new(screen, x: 2, y: 5,
    items: ["Red", "Green", "Blue",
            "Yellow", "Cyan", "Magenta"])
  CRYSTAL

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Code
  code_style = CRT::Style.new(fg: CRT::Color.rgb(180, 180, 180))
  CRT::Label.new(screen, x: 2, y: 1, text: CODE, style: code_style,
    border: CRT::Border::Rounded, pad: 1)

  # Status
  status = CRT::Label.new(screen, x: 2, y: 9, width: 30, height: 1, text: "Selected: Red")

  # Widget
  items = ["Red", "Green", "Blue", "Yellow", "Cyan", "Magenta"]
  il = CRT::ItemList.new(screen, x: 2, y: 7, items: items)
  il.on_change = ->(i : Int32) { status.text = "Selected: #{items[i]}"; nil }
  screen.focus(il)

  # Exit button
  CRT::Button.new(screen, x: 2, y: 11, text: "Exit") { screen.quit }

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
