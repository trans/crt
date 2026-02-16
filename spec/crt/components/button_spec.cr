require "../../spec_helper"

describe CRT::Button do
  describe "construction" do
    it "is focusable by default" do
      screen = test_screen
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK")
      button.focusable?.should be_true
    end

    it "auto-sizes without border: OK → 6x1" do
      screen = test_screen
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK")
      button.width.should eq(6)   # 2 text + 2 pad
      button.height.should eq(1)
    end

    it "auto-sizes with border: OK → 8x3" do
      screen = test_screen
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK", border: CRT::Border::Single)
      button.width.should eq(8)   # 2 text + 2 pad + 2 border
      button.height.should eq(3)  # 1 + 2 border
    end

    it "no border by default" do
      screen = test_screen
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK")
      button.border.should be_nil
    end

    it "uses explicit width and height" do
      screen = test_screen
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK", width: 20, height: 5)
      button.width.should eq(20)
      button.height.should eq(5)
    end
  end

  describe "#draw" do
    it "renders centered text" do
      screen = test_screen
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK")
      screen.draw

      render = screen.ansi.render
      # No border, width 6, height 1: pad(2) + "OK"(2) + pad(2)
      row0 = (0...6).map { |cx| render.cell(cx, 0).grapheme }
      row0.should contain("O")
      row0.should contain("K")
    end

    it "applies bright background when focused" do
      screen = test_screen
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK")
      screen.focus(button)
      screen.draw

      render = screen.ansi.render
      render.cell(2, 0).style.bg.should eq(CRT.theme.bright)
    end

    it "uses field colors when unfocused" do
      screen = test_screen
      button = CRT::Button.new(screen, x: 0, y: 0, text: "OK")
      screen.draw

      render = screen.ansi.render
      render.cell(2, 0).style.bg.should eq(CRT.theme.fg)
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
        CRT::Ansi::Mouse::Action::Press, 2, 0)
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
