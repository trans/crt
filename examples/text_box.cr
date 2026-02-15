require "../src/crt"

CODE = <<-CRYSTAL
  CRT::TextBox.new(screen, x: 2, y: 7,
    width: 40, height: 10,
    text: content, scrollbar: true)
  CRYSTAL

CONTENT = <<-TEXT
The quick brown fox jumps over the lazy dog. This is a classic pangram used to test fonts and keyboards.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.

Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.

Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
TEXT

CRT::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  # Code
  code_style = CRT::Style.new(fg: CRT::Color.rgb(180, 180, 180))
  CRT::Label.new(screen, x: 2, y: 1, text: CODE, style: code_style,
    border: CRT::Border::Rounded, pad: 1)

  # Widget
  tb = CRT::TextBox.new(screen, x: 2, y: 7, width: 40, height: 10,
    text: CONTENT, scrollbar: true)
  screen.focus(tb)

  # Quit hint
  hint_style = CRT::Style.new(dim: true)
  CRT::Label.new(screen, x: 2, y: 18,
    text: "Up/Down/PgUp/PgDn to scroll | Ctrl+C to quit",
    style: hint_style)

  screen.run(fps: 30) do
    if event = screen.poll_event
      case event
      when CRT::Key
        screen.quit if event.ctrl? && event.char == "c"
      end
      screen.dispatch(event)
    end
  end
end
