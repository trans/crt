require "../src/crt"

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Result label
  result = CRT::Label.new(screen, x: 2, y: 1, text: "Press the button to open a dialog.")

  # Button that opens dialog
  CRT::Button.new(screen, x: 2, y: 3, text: "Open Dialog") do
    CRT::Dialog.new(screen,
      title: "Confirm",
      message: "Are you sure you want to proceed?\nThis action cannot be undone.",
      buttons: ["Cancel", "Proceed"]) do |choice|
      if choice == 1
        result.text = "You chose: Proceed"
      else
        result.text = "You chose: Cancel"
      end
    end
  end

  # Quit hint
  CRT::Label.new(screen, x: 2, y: 6,
    text: "Tab to focus button | Enter to activate | Ctrl+C to quit")

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
