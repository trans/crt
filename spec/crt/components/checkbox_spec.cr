require "../../spec_helper"

describe CRT::Checkbox do
  describe "construction" do
    it "is focusable by default" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option")
      cb.focusable?.should be_true
    end

    it "is unchecked by default" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option")
      cb.checked?.should be_false
    end

    it "auto-sizes from text" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option")
      # "⬜ Option" = 2 + 1 + 6 = 9
      cb.width.should eq(9)
      cb.height.should eq(1)
    end

    it "auto-sizes with border" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option",
        border: CRT::Ansi::Border::Single)
      cb.width.should eq(11)  # 9 + 2
      cb.height.should eq(3)  # 1 + 2
    end

    it "uses explicit width and height" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option", width: 20, height: 3)
      cb.width.should eq(20)
      cb.height.should eq(3)
    end

    it "starts checked when specified" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option", checked: true)
      cb.checked?.should be_true
    end
  end

  describe "state" do
    it "toggle flips state" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option")
      cb.checked?.should be_false
      cb.toggle
      cb.checked?.should be_true
      cb.toggle
      cb.checked?.should be_false
    end

    it "check sets to true" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option")
      cb.check
      cb.checked?.should be_true
    end

    it "check is no-op if already checked" do
      screen = test_screen
      called = 0
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option", checked: true) { |_|
        called += 1
      }
      cb.check
      called.should eq(0)
    end

    it "uncheck sets to false" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option", checked: true)
      cb.uncheck
      cb.checked?.should be_false
    end

    it "uncheck is no-op if already unchecked" do
      screen = test_screen
      called = 0
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option") { |_|
        called += 1
      }
      cb.uncheck
      called.should eq(0)
    end

    it "checked= sets directly" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option")
      cb.checked = true
      cb.checked?.should be_true
      cb.checked = false
      cb.checked?.should be_false
    end
  end

  describe "#draw" do
    it "renders unchecked state" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option")
      screen.draw

      render = screen.ansi.render
      render.cell(0, 0).grapheme.should eq("⬜")
      render.cell(3, 0).grapheme.should eq("O")
    end

    it "renders checked state" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option", checked: true)
      screen.draw

      render = screen.ansi.render
      render.cell(0, 0).grapheme.should eq("⬛")
    end

    it "applies field style to text when focused" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option")
      screen.focus(cb)
      screen.draw

      render = screen.ansi.render
      # Text gets field style (swapped colors)
      render.cell(3, 0).style.bg.should eq(CRT.theme.fg)
      render.cell(3, 0).style.fg.should eq(CRT.theme.bg)
    end

    it "uses base style when unfocused" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option")
      screen.draw

      render = screen.ansi.render
      render.cell(3, 0).style.bg.should eq(CRT.theme.bg)
    end
  end

  describe "#handle_event" do
    it "Space toggles" do
      screen = test_screen
      received = nil
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option") { |v| received = v }
      result = cb.handle_event(CRT::Ansi::Key.char(' '))
      result.should be_true
      cb.checked?.should be_true
      received.should be_true
    end

    it "Enter toggles" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option")
      result = cb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Enter))
      result.should be_true
      cb.checked?.should be_true
    end

    it "other keys return false" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option")
      result = cb.handle_event(CRT::Ansi::Key.char('a'))
      result.should be_false
      cb.checked?.should be_false
    end

    it "mouse left click inside toggles" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option")
      click = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Left,
        CRT::Ansi::Mouse::Action::Press, 3, 0)
      result = cb.handle_event(click)
      result.should be_true
      cb.checked?.should be_true
    end

    it "mouse click outside returns false" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option")
      click = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Left,
        CRT::Ansi::Mouse::Action::Press, 20, 10)
      result = cb.handle_event(click)
      result.should be_false
      cb.checked?.should be_false
    end
  end

  describe "callback" do
    it "on_change= setter works" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option")
      received = nil
      cb.on_change = ->(v : Bool) { received = v; nil }
      cb.toggle
      received.should be_true
    end

    it "toggle is safe with no callback" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Option")
      cb.toggle  # should not raise
    end
  end

  describe "#text=" do
    it "updates label for next draw" do
      screen = test_screen
      cb = CRT::Checkbox.new(screen, x: 0, y: 0, text: "Before", width: 20)
      cb.text = "After"
      cb.text.should eq("After")
    end
  end
end
