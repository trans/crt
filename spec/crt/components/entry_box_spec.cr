require "../../spec_helper"

describe CRT::EntryBox do
  describe "construction" do
    it "is focusable by default" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5)
      eb.focusable?.should be_true
    end

    it "no border by default" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5)
      eb.border.should be_nil
    end

    it "parses initial text into lines" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5,
        text: "line one\nline two\nline three")
      eb.line_count.should eq(3)
    end

    it "empty text creates one line" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5)
      eb.line_count.should eq(1)
    end
  end

  describe "text editing" do
    it "insert character at cursor" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5)
      eb.handle_event(CRT::Ansi::Key.char('h'))
      eb.handle_event(CRT::Ansi::Key.char('i'))
      eb.text.should eq("hi")
    end

    it "backspace within line" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5,
        text: "abc")
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::End))
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Backspace))
      eb.text.should eq("ab")
    end

    it "backspace at start joins with previous line" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5,
        text: "abc\ndef")
      # Move to start of line 2
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down))
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Home))
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Backspace))
      eb.text.should eq("abcdef")
      eb.line_count.should eq(1)
      eb.cursor_line.should eq(0)
      eb.cursor_col.should eq(3) # cursor at join point
    end

    it "delete within line" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5,
        text: "abc")
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Home))
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Delete))
      eb.text.should eq("bc")
    end

    it "delete at end joins with next line" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5,
        text: "abc\ndef")
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::End))
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Delete))
      eb.text.should eq("abcdef")
      eb.line_count.should eq(1)
    end

    it "enter splits line" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5,
        text: "abcdef")
      # Move cursor to position 3
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Right))
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Right))
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Right))
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Enter))
      eb.text.should eq("abc\ndef")
      eb.line_count.should eq(2)
      eb.cursor_line.should eq(1)
      eb.cursor_col.should eq(0)
    end

    it "enter at end creates empty line" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5,
        text: "abc")
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::End))
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Enter))
      eb.text.should eq("abc\n")
      eb.line_count.should eq(2)
    end

    it "callback fires on text change" do
      screen = test_screen
      received = nil
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5) { |t|
        received = t
      }
      eb.handle_event(CRT::Ansi::Key.char('x'))
      received.should eq("x")
    end
  end

  describe "cursor movement" do
    it "Up moves to previous line" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5,
        text: "abc\ndef")
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down))
      eb.cursor_line.should eq(1)
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Up))
      eb.cursor_line.should eq(0)
    end

    it "Down moves to next line" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5,
        text: "abc\ndef")
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down))
      eb.cursor_line.should eq(1)
    end

    it "Up at first line stays" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5,
        text: "abc\ndef")
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Up))
      eb.cursor_line.should eq(0)
    end

    it "Down at last line stays" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5,
        text: "abc\ndef")
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down))
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down))
      eb.cursor_line.should eq(1)
    end

    it "Left at col 0 goes to end of previous line" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5,
        text: "abc\ndef")
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down))
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Home))
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Left))
      eb.cursor_line.should eq(0)
      eb.cursor_col.should eq(3)
    end

    it "Right at end goes to start of next line" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5,
        text: "abc\ndef")
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::End))
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Right))
      eb.cursor_line.should eq(1)
      eb.cursor_col.should eq(0)
    end

    it "Home moves to start of line" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5,
        text: "abc")
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::End))
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Home))
      eb.cursor_col.should eq(0)
    end

    it "End moves to end of line" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 5,
        text: "abc")
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::End))
      eb.cursor_col.should eq(3)
    end
  end

  describe "scrolling" do
    it "Down past visible scrolls down" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 3,
        text: "a\nb\nc\nd\ne")
      3.times { eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down)) }
      eb.cursor_line.should eq(3)
      eb.scroll_y.should eq(1)
    end

    it "Up past visible scrolls up" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 3,
        text: "a\nb\nc\nd\ne")
      4.times { eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down)) }
      4.times { eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Up)) }
      eb.cursor_line.should eq(0)
      eb.scroll_y.should eq(0)
    end

    it "PageDown moves cursor by visible height" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 3,
        text: "a\nb\nc\nd\ne\nf\ng\nh")
      eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::PageDown))
      eb.cursor_line.should eq(3)
    end
  end

  describe "#text=" do
    it "resets cursor and scroll" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 20, height: 3,
        text: "a\nb\nc\nd\ne")
      3.times { eb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down)) }
      eb.text = "new text"
      eb.cursor_line.should eq(0)
      eb.cursor_col.should eq(0)
      eb.scroll_y.should eq(0)
      eb.line_count.should eq(1)
    end
  end

  describe "#draw" do
    it "renders visible lines" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 10, height: 3,
        text: "AAA\nBBB\nCCC")
      screen.draw

      render = screen.ansi.render
      render.cell(0, 0).grapheme.should eq("A")
      render.cell(0, 1).grapheme.should eq("B")
      render.cell(0, 2).grapheme.should eq("C")
    end

    it "shows cursor on current line when focused" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 10, height: 3,
        text: "abc")
      screen.focus(eb)
      screen.draw

      render = screen.ansi.render
      # Cursor at position 0 on line 0 should have inverse style
      render.cell(0, 0).style.inverse.should be_true
    end

    it "no cursor when unfocused" do
      screen = test_screen
      eb = CRT::EntryBox.new(screen, x: 0, y: 0, width: 10, height: 3,
        text: "abc")
      screen.draw

      render = screen.ansi.render
      render.cell(0, 0).style.inverse.should be_false
    end
  end
end
