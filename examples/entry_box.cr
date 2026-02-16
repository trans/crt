require "../src/crt"

CONTENT = <<-TEXT
The quick brown fox jumps over the lazy dog.

This is an editable text box. You can type,
use arrow keys to move, Enter to split lines,
and Backspace/Delete to join them.
TEXT

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Widget
  eb = CRT::EntryBox.new(screen, x: 2, y: 1, width: 40, height: 10,
    text: CONTENT, scrollbar: true)
  screen.focus(eb)

  # Quit hint
  CRT::Label.new(screen, x: 2, y: 12,
    text: "Type to edit | Arrow keys to move | Ctrl+C to quit")

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
