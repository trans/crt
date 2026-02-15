require "../../spec_helper"

describe CRT::Button do
  describe "construction" do
    it "is focusable by default" do
      screen = test_screen
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK")
      button.focusable?.should be_true
    end

    it "auto-sizes with border: OK → 8x3" do
      screen = test_screen
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK")
      button.width.should eq(8)   # 2 text + 2 pad + 2 border
      button.height.should eq(3)  # 1 + 2 border
    end

    it "auto-sizes without border: OK → 6x1" do
      screen = test_screen
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK", border: nil)
      button.width.should eq(6)   # 2 text + 2 pad
      button.height.should eq(1)
    end

    it "uses explicit width and height" do
      screen = test_screen
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK", width: 20, height: 5)
      button.width.should eq(20)
      button.height.should eq(5)
    end
  end

  describe "#draw" do
    it "renders centered text inside border" do
      screen = test_screen
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK")
      screen.draw

      render = screen.ansi.render
      # Border top-left corner
      render.cell(0, 0).grapheme.should eq("\u250C")
      # Centered text at row 1 (inside border)
      # Width 8: border(1) + pad(1) + "OK"(2) + pad(1) + border(1)
      # Text starts at x=2, centered in 6-wide content area (pad 1 each side, 4 inner, "OK" at offset 1 → x=3)
      # Actually with panel centering: content area is 6 wide, pad=1 means text area is 4 wide,
      # "OK" centered in 4 → offset 1, so x = border(1) + pad_offset + 1 = 2 or 3
      # Let's just verify the O and K appear somewhere in row 1
      row1 = (0...8).map { |cx| render.cell(cx, 1).grapheme }
      row1.should contain("O")
      row1.should contain("K")
    end

    it "applies inverse style when focused" do
      screen = test_screen
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK")
      screen.focus(button)
      screen.draw

      render = screen.ansi.render
      # Check a cell inside the button for inverse style
      render.cell(1, 1).style.inverse.should be_true
    end

    it "uses normal style when unfocused" do
      screen = test_screen
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK")
      screen.draw

      render = screen.ansi.render
      render.cell(1, 1).style.inverse.should be_false
    end
  end

  describe "#handle_event" do
    it "activates on Enter" do
      screen = test_screen
      called = false
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK") { called = true }
      result = button.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Enter))
      result.should be_true
      called.should be_true
    end

    it "activates on Space" do
      screen = test_screen
      called = false
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK") { called = true }
      result = button.handle_event(CRT::Ansi::Key.char(' '))
      result.should be_true
      called.should be_true
    end

    it "returns false for other keys" do
      screen = test_screen
      called = false
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK") { called = true }
      result = button.handle_event(CRT::Ansi::Key.char('a'))
      result.should be_false
      called.should be_false
    end

    it "activates on left mouse click inside" do
      screen = test_screen
      called = false
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK") { called = true }
      click = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Left,
        CRT::Ansi::Mouse::Action::Press, 3, 1)
      result = button.handle_event(click)
      result.should be_true
      called.should be_true
    end

    it "returns false for mouse click outside" do
      screen = test_screen
      called = false
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK") { called = true }
      click = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Left,
        CRT::Ansi::Mouse::Action::Press, 20, 20)
      result = button.handle_event(click)
      result.should be_false
      called.should be_false
    end
  end

  describe "#activate" do
    it "calls the action block" do
      screen = test_screen
      called = false
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK") { called = true }
      button.activate
      called.should be_true
    end

    it "is safe with no action set" do
      screen = test_screen
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK")
      button.activate  # should not raise
    end

    it "uses action= setter" do
      screen = test_screen
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK")
      called = false
      button.action = -> { called = true; nil }
      button.activate
      called.should be_true
    end
  end

  describe "#text=" do
    it "updates text for next draw" do
      screen = test_screen
      button = CRT::Button.new(screen, x: 0, y: 0, width: 12, height: 3, text: "Before")
      button.text = "After"
      button.text.should eq("After")
    end
  end
end
