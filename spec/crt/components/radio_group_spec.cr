require "../../spec_helper"

describe CRT::RadioGroup do
  describe "construction" do
    it "is focusable by default" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      rg.focusable?.should be_true
    end

    it "selected defaults to 0" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      rg.selected.should eq(0)
    end

    it "auto-sizes from items" do
      screen = test_screen
      # "⬤ Long Option" = 1 + 1 + 11 = 13 wide, 3 items tall
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0,
        items: ["Short", "Long Option", "Mid"])
      rg.width.should eq(13)
      rg.height.should eq(3)
    end

    it "auto-sizes with border" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0,
        items: ["A", "B"], border: CRT::Ansi::Border::Single)
      # "⬤ A" = 1 + 1 + 1 = 3 + border 2 = 5
      rg.width.should eq(5)
      rg.height.should eq(4) # 2 items + 2 border
    end

    it "uses explicit width and height" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0,
        items: ["A", "B"], width: 30, height: 10)
      rg.width.should eq(30)
      rg.height.should eq(10)
    end
  end

  describe "selection" do
    it "selected= updates and clamps" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      rg.selected = 2
      rg.selected.should eq(2)
      rg.selected = 10
      rg.selected.should eq(2)
      rg.selected = -1
      rg.selected.should eq(0)
    end

    it "selected_item returns correct string" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      rg.selected_item.should eq("A")
      rg.selected = 2
      rg.selected_item.should eq("C")
    end

    it "Down changes selection" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      rg.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down))
      rg.selected.should eq(1)
    end

    it "Up changes selection" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B", "C"],
        selected: 2)
      rg.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Up))
      rg.selected.should eq(1)
    end

    it "Up at 0 stays at 0" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      rg.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Up))
      rg.selected.should eq(0)
    end

    it "Down at last stays at last" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B", "C"],
        selected: 2)
      rg.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down))
      rg.selected.should eq(2)
    end

    it "callback fires on change" do
      screen = test_screen
      received = nil
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B", "C"]) { |i|
        received = i
      }
      rg.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down))
      received.should eq(1)
    end

    it "callback does not fire when selecting same index" do
      screen = test_screen
      called = 0
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B", "C"]) { |_|
        called += 1
      }
      rg.select(0) # already at 0
      called.should eq(0)
    end
  end

  describe "#draw" do
    it "renders selected and unselected marks" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B"])
      screen.draw

      render = screen.ansi.render
      # Row 0: "⬤ A" — selected
      render.cell(0, 0).grapheme.should eq("⬤")
      render.cell(2, 0).grapheme.should eq("A")
      # Row 1: "◯ B" — unselected
      render.cell(0, 1).grapheme.should eq("◯")
      render.cell(2, 1).grapheme.should eq("B")
    end

    it "applies field_focus style to selected item text when focused" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B"])
      screen.focus(rg)
      screen.draw

      render = screen.ansi.render
      # Selected + focused: field_focus (bright bg)
      render.cell(2, 0).style.bg.should eq(CRT.theme.bright)
      # Unselected: base style
      render.cell(2, 1).style.bg.should eq(CRT.theme.bg)
    end

    it "no focus style when unfocused" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B"])
      screen.draw

      render = screen.ansi.render
      # Selected but unfocused: field style (fg as bg)
      render.cell(2, 0).style.bg.should eq(CRT.theme.fg)
    end
  end

  describe "#handle_event" do
    it "Space fires callback" do
      screen = test_screen
      received = nil
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B"]) { |i|
        received = i
      }
      rg.handle_event(CRT::Ansi::Key.char(' ')).should be_true
      received.should eq(0)
    end

    it "Enter fires callback" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B"])
      rg.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Enter)).should be_true
    end

    it "mouse click selects clicked item" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      click = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Left,
        CRT::Ansi::Mouse::Action::Press, 2, 2)
      rg.handle_event(click).should be_true
      rg.selected.should eq(2)
    end

    it "mouse click outside returns false" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B"])
      click = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Left,
        CRT::Ansi::Mouse::Action::Press, 30, 30)
      rg.handle_event(click).should be_false
    end

    it "other keys return false" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B"])
      rg.handle_event(CRT::Ansi::Key.char('a')).should be_false
    end
  end

  describe "callback" do
    it "on_change= setter works" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B"])
      received = nil
      rg.on_change = ->(i : Int32) { received = i; nil }
      rg.select(1)
      received.should eq(1)
    end

    it "safe with no callback" do
      screen = test_screen
      rg = CRT::RadioGroup.new(screen, x: 0, y: 0, items: ["A", "B"])
      rg.select(1) # should not raise
    end
  end
end
