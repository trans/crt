require "../src/crt"

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  tab_widget = uninitialized CRT::Tabs

  ui = CRT.build(screen) do
    tab_widget = tabs id: :tabs, x: 2, y: 1, width: 50, height: 18,
         tab_type: CRT::TabType::Underline, decor: CRT::Decor::Bevel do
      page "Profile" do
        label "Name"
        entry id: :name, width: 46, border: nil, pad: 0
        label ""
        label "Email"
        entry id: :email, width: 46, border: nil, pad: 0
        label ""
        label "Bio"
        entry id: :bio, width: 46, border: nil, pad: 0
      end

      page "Settings" do
        checkbox "Newsletter"
        checkbox "Notifications"
        label ""
        label "Theme"
        radio_group items: ["Light", "Dark", "System"]
      end

      page "About" do
        label "CRT Widget Toolkit v#{CRT::VERSION}"
        label "A terminal UI library for Crystal."
      end
    end

    button id: :toggle, x: 2, y: 20, text: "Toggle Style" do
      tab_widget.tab_type = tab_widget.tab_type.folder? ? CRT::TabType::Underline : CRT::TabType::Folder
    end

    label x: 2, y: 22,
      text: "←/→ switch tabs | Tab enters page | Shift+Tab goes back | Ctrl+C quits"
  end

  screen.focus(tab_widget)

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
