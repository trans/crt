require "../src/crt"

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Title
  title_style = CRT::Style.new(bold: true, fg: CRT::Color.rgb(120, 200, 255))
  CRT::Label.new(screen, x: 2, y: 1, text: "CRT Widget Demo", style: title_style)

  # Name field
  CRT::Label.new(screen, x: 2, y: 3, text: "Name:")
  name_entry = CRT::Entry.new(screen, x: 10, y: 3, width: 30)

  # Email field
  CRT::Label.new(screen, x: 2, y: 6, text: "Email:")
  email_entry = CRT::Entry.new(screen, x: 10, y: 6, width: 30)

  # Options
  newsletter = CRT::Checkbox.new(screen, x: 10, y: 9, text: "Subscribe to newsletter")
  dark_mode = CRT::Checkbox.new(screen, x: 10, y: 10, text: "Enable dark mode", checked: true)

  # Status label
  status_style = CRT::Style.new(fg: CRT::Color.rgb(100, 255, 100))
  status = CRT::Label.new(screen, x: 2, y: 16, width: 50, height: 1,
    text: "", style: status_style)

  # Submit button
  submit = CRT::Button.new(screen, x: 10, y: 12, text: "Submit") do
    parts = [] of String
    parts << name_entry.text unless name_entry.text.empty?
    parts << email_entry.text unless email_entry.text.empty?
    parts << "newsletter" if newsletter.checked?
    parts << "dark mode" if dark_mode.checked?
    status.text = "Submitted: #{parts.join(", ")}"
  end

  # Quit hint
  hint_style = CRT::Style.new(dim: true)
  CRT::Label.new(screen, x: 2, y: 18, text: "Tab/Shift+Tab to navigate | Ctrl+C to quit",
    style: hint_style)

  # Focus the first entry
  screen.focus(name_entry)

  # Main loop
  screen.run(fps: 30) do
    if event = screen.poll_event
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
