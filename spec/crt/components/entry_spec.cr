require "../../spec_helper"

private def send_key(entry, code : CRT::Ansi::Key::Code)
  entry.handle_event(CRT::Ansi::Key.new(code))
end

private def send_char(entry, ch : Char)
  entry.handle_event(CRT::Ansi::Key.char(ch))
end

describe CRT::Entry do
  describe "construction" do
    it "is focusable by default" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20)
      entry.focusable?.should be_true
    end

    it "computes height from border: 3 with border" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20)
      entry.height.should eq(3)
    end

    it "computes height from border: 1 without border" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, border: nil)
      entry.height.should eq(1)
    end

    it "stores initial text" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hello")
      entry.text.should eq("Hello")
    end

    it "cursor starts at 0" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hello")
      entry.cursor.should eq(0)
    end
  end

  describe "#text=" do
    it "updates text" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hello")
      entry.text = "World"
      entry.text.should eq("World")
    end

    it "clamps cursor when text shrinks" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hello")
      entry.cursor = 5  # end of "Hello"
      entry.text = "Hi"
      entry.cursor.should eq(2)
    end
  end

  describe "#cursor=" do
    it "clamps to valid range" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hello")
      entry.cursor = 100
      entry.cursor.should eq(5)
      entry.cursor = -5
      entry.cursor.should eq(0)
    end
  end

  describe "cursor movement" do
    it "Left moves cursor left" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hello")
      entry.cursor = 3
      send_key(entry, CRT::Ansi::Key::Code::Left)
      entry.cursor.should eq(2)
    end

    it "Right moves cursor right" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hello")
      send_key(entry, CRT::Ansi::Key::Code::Right)
      entry.cursor.should eq(1)
    end

    it "Home moves cursor to 0" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hello")
      entry.cursor = 3
      send_key(entry, CRT::Ansi::Key::Code::Home)
      entry.cursor.should eq(0)
    end

    it "End moves cursor to end" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hello")
      send_key(entry, CRT::Ansi::Key::Code::End)
      entry.cursor.should eq(5)
    end

    it "Left at 0 stays at 0" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hello")
      send_key(entry, CRT::Ansi::Key::Code::Left)
      entry.cursor.should eq(0)
    end

    it "Right at end stays at end" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hello")
      entry.cursor = 5
      send_key(entry, CRT::Ansi::Key::Code::Right)
      entry.cursor.should eq(5)
    end
  end

  describe "text editing" do
    it "inserts character at cursor" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hllo")
      entry.cursor = 1
      send_char(entry, 'e')
      entry.text.should eq("Hello")
      entry.cursor.should eq(2)
    end

    it "inserts at beginning" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "ello")
      send_char(entry, 'H')
      entry.text.should eq("Hello")
      entry.cursor.should eq(1)
    end

    it "inserts at end" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hell")
      entry.cursor = 4
      send_char(entry, 'o')
      entry.text.should eq("Hello")
      entry.cursor.should eq(5)
    end

    it "backspace deletes before cursor" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hello")
      entry.cursor = 3
      send_key(entry, CRT::Ansi::Key::Code::Backspace)
      entry.text.should eq("Helo")
      entry.cursor.should eq(2)
    end

    it "backspace at 0 is no-op" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hello")
      send_key(entry, CRT::Ansi::Key::Code::Backspace)
      entry.text.should eq("Hello")
      entry.cursor.should eq(0)
    end

    it "delete removes at cursor" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hello")
      entry.cursor = 2
      send_key(entry, CRT::Ansi::Key::Code::Delete)
      entry.text.should eq("Helo")
      entry.cursor.should eq(2)
    end

    it "delete at end is no-op" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hello")
      entry.cursor = 5
      send_key(entry, CRT::Ansi::Key::Code::Delete)
      entry.text.should eq("Hello")
    end
  end

  describe "#draw" do
    it "renders text inside border" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 12, text: "Hello")
      screen.draw

      render = screen.ansi.render
      # Border top-left
      render.cell(0, 0).grapheme.should eq("\u250C")
      # Text at row 1, col 2 (border + pad)
      render.cell(2, 1).grapheme.should eq("H")
      render.cell(3, 1).grapheme.should eq("e")
      render.cell(4, 1).grapheme.should eq("l")
      render.cell(5, 1).grapheme.should eq("l")
      render.cell(6, 1).grapheme.should eq("o")
    end

    it "shows inverse cursor when focused" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 12, text: "Hello")
      screen.focus(entry)
      screen.draw

      render = screen.ansi.render
      # Cursor at position 0 → first char "H" should be inverse
      render.cell(2, 1).grapheme.should eq("H")
      render.cell(2, 1).style.inverse.should be_true
      # Next char should not be inverse
      render.cell(3, 1).style.inverse.should be_false
    end

    it "hides cursor styling when unfocused" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 12, text: "Hello")
      screen.draw

      render = screen.ansi.render
      render.cell(2, 1).style.inverse.should be_false
    end

    it "draws inverse space at end of text when cursor is at end" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 12, text: "Hi")
      entry.cursor = 2
      screen.focus(entry)
      screen.draw

      render = screen.ansi.render
      # "Hi" at cols 2,3 — cursor at col 4
      render.cell(4, 1).grapheme.should eq(" ")
      render.cell(4, 1).style.inverse.should be_true
    end
  end

  describe "scrolling" do
    it "scrolls right when cursor moves past visible area" do
      screen = test_screen
      # width 8, border + pad = inset 2 each side → 4 visible columns
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 8, text: "abcdefgh")
      screen.focus(entry)

      # Move cursor to end
      entry.cursor = 8
      screen.draw

      render = screen.ansi.render
      # Should show the tail of the text, with cursor space at end
      # The last visible chars before cursor should include some tail chars
      # At minimum, the cursor (inverse space) should be visible
      row = (2..5).map { |cx| render.cell(cx, 1) }
      row.last.style.inverse.should be_true
    end

    it "scrolls left when cursor moves before visible area" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 8, text: "abcdefgh")
      screen.focus(entry)

      # Scroll right first
      entry.cursor = 8
      screen.draw

      # Now go back to start
      entry.cursor = 0
      screen.draw

      render = screen.ansi.render
      # Should show beginning: "a" with inverse cursor
      render.cell(2, 1).grapheme.should eq("a")
      render.cell(2, 1).style.inverse.should be_true
    end
  end

  describe "event handling" do
    it "Enter triggers on_submit with current text" do
      screen = test_screen
      submitted = nil
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hello") { |t|
        submitted = t
      }
      send_key(entry, CRT::Ansi::Key::Code::Enter)
      submitted.should eq("Hello")
    end

    it "mouse click inside positions cursor" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hello")
      # Click at x=5, inside the entry. With border(1) + pad(1) = offset 2,
      # click at x=5 means display column 3, which is grapheme index 3 ("l")
      click = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Left,
        CRT::Ansi::Mouse::Action::Press, 5, 1)
      entry.handle_event(click).should be_true
      entry.cursor.should eq(3)
    end

    it "mouse click outside returns false" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hello")
      click = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Left,
        CRT::Ansi::Mouse::Action::Press, 30, 10)
      entry.handle_event(click).should be_false
    end

    it "unhandled keys return false" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20)
      send_key(entry, CRT::Ansi::Key::Code::F1).should be_false
    end

    it "on_submit= setter works" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20, text: "Hi")
      submitted = nil
      entry.on_submit = ->(t : String) { submitted = t; nil }
      send_key(entry, CRT::Ansi::Key::Code::Enter)
      submitted.should eq("Hi")
    end

    it "Enter is safe with no callback" do
      screen = test_screen
      entry = CRT::Entry.new(screen, x: 0, y: 0, width: 20)
      send_key(entry, CRT::Ansi::Key::Code::Enter)  # should not raise
    end
  end
end
