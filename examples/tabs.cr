require "../src/crt"

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Tabs with a border
  tabs = CRT::Tabs.new(screen, x: 2, y: 1, width: 50, height: 18,
    tab_type: CRT::TabType::Underline, decor: CRT::Decor::Bevel)

  # --- Profile tab ---
  profile = tabs.add("Profile")

  CRT::Label.new(screen, x: 0, y: 0, text: "Name")
    .tap { |w| profile << w }
  name_entry = CRT::Entry.new(screen, x: 0, y: 0, width: 46,
    border: nil, pad: 0)
  profile << name_entry

  CRT::Label.new(screen, x: 0, y: 0, text: "")
    .tap { |w| profile << w }
  CRT::Label.new(screen, x: 0, y: 0, text: "Email")
    .tap { |w| profile << w }
  email_entry = CRT::Entry.new(screen, x: 0, y: 0, width: 46,
    border: nil, pad: 0)
  profile << email_entry

  CRT::Label.new(screen, x: 0, y: 0, text: "")
    .tap { |w| profile << w }
  CRT::Label.new(screen, x: 0, y: 0, text: "Bio")
    .tap { |w| profile << w }
  bio_entry = CRT::Entry.new(screen, x: 0, y: 0, width: 46,
    border: nil, pad: 0)
  profile << bio_entry

  # --- Settings tab ---
  settings = tabs.add("Settings")

  newsletter = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Newsletter")
  settings << newsletter

  notifications = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Notifications")
  settings << notifications

  CRT::Label.new(screen, x: 0, y: 0, text: "")
    .tap { |w| settings << w }
  CRT::Label.new(screen, x: 0, y: 0, text: "Theme")
    .tap { |w| settings << w }
  theme = CRT::RadioGroup.new(screen, x: 0, y: 0,
    items: ["Light", "Dark", "System"])
  settings << theme

  # --- About tab ---
  about = tabs.add("About")
  CRT::Label.new(screen, x: 0, y: 0, text: "CRT Widget Toolkit v#{CRT::VERSION}")
    .tap { |w| about << w }
  CRT::Label.new(screen, x: 0, y: 0, text: "A terminal UI library for Crystal.")
    .tap { |w| about << w }

  # Toggle tab style
  CRT::Button.new(screen, x: 2, y: 20, text: "Toggle Style") do
    tabs.tab_type = tabs.tab_type.folder? ? CRT::TabType::Underline : CRT::TabType::Folder
  end

  # Hint
  CRT::Label.new(screen, x: 2, y: 22,
    text: "←/→ switch tabs | Tab enters page | Shift+Tab goes back | Ctrl+C quits")

  # Focus tabs
  screen.focus(tabs)

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
