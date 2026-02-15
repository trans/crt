require "../../spec_helper"

describe CRT::TextBox do
  describe "construction" do
    it "is focusable by default" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 20, height: 5)
      tb.focusable?.should be_true
    end

    it "no border by default" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 20, height: 5)
      tb.border.should be_nil
    end

    it "stores text" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 20, height: 5,
        text: "hello")
      tb.text.should eq("hello")
    end
  end

  describe "wrapping" do
    it "Wrap::None splits on newlines only" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 10, height: 5,
        text: "abcdefghijklmno", wrap: CRT::Ansi::Wrap::None)
      tb.line_count.should eq(1)
    end

    it "Wrap::Char wraps at character width" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 5, height: 10,
        text: "abcdefghij", wrap: CRT::Ansi::Wrap::Char)
      tb.line_count.should eq(2)
    end

    it "Wrap::Word wraps at word boundaries" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 10, height: 10,
        text: "one two three four", wrap: CRT::Ansi::Wrap::Word)
      tb.line_count.should be >= 2
    end

    it "preserves explicit newlines in wrap modes" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 80, height: 10,
        text: "line one\nline two\nline three", wrap: CRT::Ansi::Wrap::Word)
      tb.line_count.should eq(3)
    end

    it "accounts for scrollbar in wrap width" do
      screen = test_screen
      # width 6, scrollbar takes 1 → avail 5
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 6, height: 3,
        text: "abcdefghij", wrap: CRT::Ansi::Wrap::Char, scrollbar: true)
      tb.line_count.should eq(2) # 10 chars / 5 wide = 2 lines
    end
  end

  describe "vertical scrolling" do
    it "Down scrolls down" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 20, height: 3,
        text: "a\nb\nc\nd\ne", wrap: CRT::Ansi::Wrap::None)
      tb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down))
      tb.scroll_y.should eq(1)
    end

    it "Up scrolls up" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 20, height: 3,
        text: "a\nb\nc\nd\ne", wrap: CRT::Ansi::Wrap::None)
      tb.scroll_to(2)
      tb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Up))
      tb.scroll_y.should eq(1)
    end

    it "Home goes to top" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 20, height: 3,
        text: "a\nb\nc\nd\ne", wrap: CRT::Ansi::Wrap::None)
      tb.scroll_to(2)
      tb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Home))
      tb.scroll_y.should eq(0)
    end

    it "End goes to bottom" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 20, height: 3,
        text: "a\nb\nc\nd\ne", wrap: CRT::Ansi::Wrap::None)
      tb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::End))
      tb.scroll_y.should eq(2) # 5 lines - 3 visible = 2
    end

    it "clamps at top" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 20, height: 3,
        text: "a\nb\nc\nd\ne", wrap: CRT::Ansi::Wrap::None)
      tb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Up))
      tb.scroll_y.should eq(0)
    end

    it "clamps at bottom" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 20, height: 3,
        text: "a\nb\nc\nd\ne", wrap: CRT::Ansi::Wrap::None)
      tb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::End))
      tb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down))
      tb.scroll_y.should eq(2)
    end

    it "PageDown scrolls by visible height" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 20, height: 3,
        text: "a\nb\nc\nd\ne\nf\ng\nh\ni\nj", wrap: CRT::Ansi::Wrap::None)
      tb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::PageDown))
      tb.scroll_y.should eq(3)
    end
  end

  describe "horizontal scrolling (Wrap::None)" do
    it "Right scrolls right" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 5, height: 3,
        text: "abcdefghijklmno", wrap: CRT::Ansi::Wrap::None)
      tb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Right))
      tb.scroll_x.should eq(1)
    end

    it "Left scrolls left" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 5, height: 3,
        text: "abcdefghijklmno", wrap: CRT::Ansi::Wrap::None)
      tb.scroll_to(0, 3)
      tb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Left))
      tb.scroll_x.should eq(2)
    end

    it "no horizontal scroll in Word wrap" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 5, height: 3,
        text: "abcdefghijklmno", wrap: CRT::Ansi::Wrap::Word)
      tb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Right)).should be_false
    end

    it "no horizontal scroll in Char wrap" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 5, height: 3,
        text: "abcdefghijklmno", wrap: CRT::Ansi::Wrap::Char)
      tb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Right)).should be_false
    end
  end

  describe "#draw" do
    it "renders visible lines" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 10, height: 3,
        text: "AAA\nBBB\nCCC\nDDD", wrap: CRT::Ansi::Wrap::None)
      screen.draw

      render = screen.ansi.render
      render.cell(0, 0).grapheme.should eq("A")
      render.cell(0, 1).grapheme.should eq("B")
      render.cell(0, 2).grapheme.should eq("C")
    end

    it "renders scrolled content" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 10, height: 2,
        text: "AAA\nBBB\nCCC\nDDD", wrap: CRT::Ansi::Wrap::None)
      tb.scroll_to(2)
      screen.draw

      render = screen.ansi.render
      render.cell(0, 0).grapheme.should eq("C")
      render.cell(0, 1).grapheme.should eq("D")
    end

    it "renders scrollbar when enabled and content overflows" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 10, height: 3,
        text: "A\nB\nC\nD\nE", wrap: CRT::Ansi::Wrap::None, scrollbar: true)
      screen.draw

      render = screen.ansi.render
      # Scrollbar in rightmost column (x=9), should have track bg
      sb_cell = render.cell(9, 0)
      track_or_thumb = sb_cell.style.bg == CRT::Ansi::Color.indexed(8) ||
                       sb_cell.style.bg == CRT::Ansi::Color.indexed(7)
      track_or_thumb.should be_true
    end

    it "no scrollbar when content fits" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 10, height: 5,
        text: "A\nB\nC", wrap: CRT::Ansi::Wrap::None, scrollbar: true)
      screen.draw

      render = screen.ansi.render
      # No scrollbar needed — rightmost column should not have track bg
      render.cell(9, 0).style.bg.should_not eq(CRT::Ansi::Color.indexed(8))
    end
  end

  describe "#text=" do
    it "recomputes lines" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 10, height: 3,
        text: "short", wrap: CRT::Ansi::Wrap::None)
      tb.line_count.should eq(1)
      tb.text = "a\nb\nc"
      tb.line_count.should eq(3)
    end

    it "clamps scroll position" do
      screen = test_screen
      tb = CRT::TextBox.new(screen, x: 0, y: 0, width: 10, height: 3,
        text: "a\nb\nc\nd\ne", wrap: CRT::Ansi::Wrap::None)
      tb.scroll_to(2)
      tb.text = "short"
      tb.scroll_y.should eq(0)
    end
  end
end
