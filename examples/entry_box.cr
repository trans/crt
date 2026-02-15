require "../src/crt"

CODE = <<-CRYSTAL
  CRT::EntryBox.new(screen, x: 2, y: 7,
    width: 40, height: 10,
    text: content, scrollbar: true)
  CRYSTAL

CONTENT = <<-TEXT
The quick brown fox jumps over the lazy dog.

This is an editable text box. You can type,
use arrow keys to move, Enter to split lines,
and Backspace/Delete to join them.
TEXT

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Code
  code_style = CRT::Style.new(fg: CRT::Color.rgb(180, 180, 180))
  CRT::Label.new(screen, x: 2, y: 1, text: CODE, style: code_style,
    border: CRT::Border::Rounded, pad: 1)

  # Widget
  eb = CRT::EntryBox.new(screen, x: 2, y: 7, width: 40, height: 10,
    text: CONTENT, scrollbar: true)
  screen.focus(eb)

  # Quit hint
  hint_style = CRT::Style.new(dim: true)
  CRT::Label.new(screen, x: 2, y: 18,
    text: "Type to edit | Arrow keys to move | Ctrl+C to quit",
    style: hint_style)

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
