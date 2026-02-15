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

  # Theme selection
  CRT::Label.new(screen, x: 2, y: 11, text: "Theme:")
  theme = CRT::RadioGroup.new(screen, x: 10, y: 11, items: ["Light", "Dark", "System"])

  # Progress bar
  CRT::Label.new(screen, x: 2, y: 15, text: "Progress:")
  fill_style = CRT::Style.new(fg: CRT::Color.rgb(80, 220, 120))
  empty_style = CRT::Style.new(fg: CRT::Color.rgb(60, 60, 60))
  progress = CRT::ProgressBar.new(screen, x: 13, y: 15, width: 27,
    fill_style: fill_style, empty_style: empty_style)

  # Status label
  status_style = CRT::Style.new(fg: CRT::Color.rgb(100, 255, 100))
  status = CRT::Label.new(screen, x: 2, y: 21, width: 50, height: 1,
    text: "", style: status_style)

  # Submit button
  submit = CRT::Button.new(screen, x: 10, y: 17, text: "Submit") do
    progress.value = (progress.value + 0.1).clamp(0.0, 1.0)
    pct = (progress.value * 100).to_i
    parts = [] of String
    parts << name_entry.text unless name_entry.text.empty?
    parts << email_entry.text unless email_entry.text.empty?
    parts << "newsletter" if newsletter.checked?
    parts << theme.selected_item
    status.text = "Submitted (#{pct}%): #{parts.join(", ")}"
  end

  # Quit hint
  hint_style = CRT::Style.new(dim: true)
  CRT::Label.new(screen, x: 2, y: 23, text: "Tab/Shift+Tab to navigate | Ctrl+C to quit",
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
