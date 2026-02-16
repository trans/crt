require "../src/crt"

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Shared boxing for connected borders
  boxing = CRT::Boxing.new(border: CRT::Border::Rounded)

  # Left frame — personal info
  left = CRT::Frame.new(screen, x: 2, y: 1, width: 25,
    box: boxing, title: "Personal")

  CRT::Label.new(screen, x: 0, y: 0, text: "Name:")
    .tap { |w| left << w }
  name_entry = CRT::Entry.new(screen, x: 0, y: 0, width: 23,
    border: nil, pad: 0)
  left << name_entry

  CRT::Label.new(screen, x: 0, y: 0, text: "Email:")
    .tap { |w| left << w }
  email_entry = CRT::Entry.new(screen, x: 0, y: 0, width: 23,
    border: nil, pad: 0)
  left << email_entry

  # Right frame — preferences (shares left edge with left frame)
  right = CRT::Frame.new(screen, x: 26, y: 1, width: 25,
    height: left.height,
    box: boxing, title: "Settings")

  newsletter = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Newsletter")
  right << newsletter

  CRT::Label.new(screen, x: 0, y: 0, text: "Theme:")
    .tap { |w| right << w }
  theme = CRT::RadioGroup.new(screen, x: 0, y: 0,
    items: ["Light", "Dark", "System"])
  right << theme

  # Status
  bottom_y = left.y + left.height + 1
  status = CRT::Label.new(screen, x: 2, y: bottom_y, width: 49, height: 1, text: "")

  # Submit button
  CRT::Button.new(screen, x: 2, y: bottom_y + 2, text: "Submit") do
    parts = [] of String
    parts << name_entry.text unless name_entry.text.empty?
    parts << email_entry.text unless email_entry.text.empty?
    parts << "newsletter" if newsletter.checked?
    parts << theme.selected_item
    status.text = "Submitted: #{parts.join(", ")}"
  end

  # Quit button
  CRT::Button.new(screen, x: 16, y: bottom_y + 2, text: "Quit") do
    screen.quit
  end

  # Hint
  CRT::Label.new(screen, x: 2, y: bottom_y + 4,
    text: "Tab/Shift+Tab to navigate | Ctrl+C to quit")

  # Focus the first entry
  screen.focus(left)

  screen.run(fps: 30) do
    screen.each_event do |event|
      case event
      when CRT::Key
        if event.ctrl? && event.char == "c"
          screen.quit
          next
        end
      end
      screen.dispatch(event)
    end
  end
end
