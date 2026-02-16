require "../../spec_helper"

describe CRT::ItemList do
  describe "construction" do
    it "is focusable by default" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      il.focusable?.should be_true
    end

    it "selected defaults to 0" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      il.selected.should eq(0)
    end

    it "auto-sizes from items and marks" do
      screen = test_screen
      # "◄ Long Item ►" = 1 + 1 + 9 + 1 + 1 = 13
      il = CRT::ItemList.new(screen, x: 0, y: 0,
        items: ["Short", "Long Item", "Mid"])
      il.width.should eq(13)
      il.height.should eq(1)
    end

    it "auto-sizes with border" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0,
        items: ["A", "B"], border: CRT::Ansi::Border::Single)
      # "◄ A ►" = 1 + 1 + 1 + 1 + 1 = 5 + border 2 = 7
      il.width.should eq(7)
      il.height.should eq(3)
    end

    it "uses explicit width and height" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0,
        items: ["A", "B"], width: 30, height: 3)
      il.width.should eq(30)
      il.height.should eq(3)
    end

    it "clamps initial selected" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0,
        items: ["A", "B", "C"], selected: 10)
      il.selected.should eq(2)
    end
  end

  describe "selection" do
    it "Right cycles forward" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      il.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Right))
      il.selected.should eq(1)
    end

    it "Left cycles backward" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B", "C"],
        selected: 1)
      il.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Left))
      il.selected.should eq(0)
    end

    it "Right wraps to first" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B", "C"],
        selected: 2)
      il.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Right))
      il.selected.should eq(0)
    end

    it "Left wraps to last" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      il.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Left))
      il.selected.should eq(2)
    end

    it "Home selects first" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B", "C"],
        selected: 2)
      il.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Home))
      il.selected.should eq(0)
    end

    it "End selects last" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      il.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::End))
      il.selected.should eq(2)
    end

    it "selected_item returns correct string" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["Red", "Green", "Blue"])
      il.selected_item.should eq("Red")
      il.selected = 2
      il.selected_item.should eq("Blue")
    end

    it "callback fires on change" do
      screen = test_screen
      received = nil
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B", "C"]) { |i|
        received = i
      }
      il.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Right))
      received.should eq(1)
    end

    it "callback does not fire when selecting same index" do
      screen = test_screen
      called = 0
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B", "C"]) { |_|
        called += 1
      }
      il.select(0) # already at 0
      called.should eq(0)
    end
  end

  describe "#draw" do
    it "renders marks and current item" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["Red", "Green", "Blue"])
      screen.draw

      render = screen.ansi.render
      render.cell(0, 0).grapheme.should eq("◄")
      # Item "Red" somewhere in the middle
      found = false
      (1...il.width - 1).each do |cx|
        if render.cell(cx, 0).grapheme == "R"
          found = true
          break
        end
      end
      found.should be_true
      # Right mark at end
      render.cell(il.width - 1, 0).grapheme.should eq("►")
    end

    it "focus style applies only to item text" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B"])
      screen.focus(il)
      screen.draw

      render = screen.ansi.render
      # Left mark: base style
      render.cell(0, 0).style.bg.should eq(CRT.theme.bg)
      # Item area: field style (swapped colors)
      render.cell(2, 0).style.bg.should eq(CRT.theme.fg)
    end

    it "unfocused style uses base colors" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B"])
      screen.draw

      render = screen.ansi.render
      render.cell(2, 0).style.bg.should eq(CRT.theme.bg)
    end

    it "updates display after selection change" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["AAA", "BBB"])
      il.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Right))
      screen.draw

      render = screen.ansi.render
      found = false
      (1...il.width - 1).each do |cx|
        if render.cell(cx, 0).grapheme == "B"
          found = true
          break
        end
      end
      found.should be_true
    end
  end

  describe "#handle_event" do
    it "Enter fires callback" do
      screen = test_screen
      received = nil
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B"]) { |i|
        received = i
      }
      il.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Enter)).should be_true
      received.should eq(0)
    end

    it "Space fires callback" do
      screen = test_screen
      received = nil
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B"]) { |i|
        received = i
      }
      il.handle_event(CRT::Ansi::Key.char(' ')).should be_true
      received.should eq(0)
    end

    it "other keys return false" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B"])
      il.handle_event(CRT::Ansi::Key.char('z')).should be_false
    end

    it "mouse click left mark area cycles backward" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B", "C"],
        selected: 1)
      click = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Left,
        CRT::Ansi::Mouse::Action::Press, 0, 0)
      il.handle_event(click).should be_true
      il.selected.should eq(0)
    end

    it "mouse click right mark area cycles forward" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      click = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Left,
        CRT::Ansi::Mouse::Action::Press, il.width - 1, 0)
      il.handle_event(click).should be_true
      il.selected.should eq(1)
    end
  end

  describe "callback" do
    it "on_change= setter works" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B"])
      received = nil
      il.on_change = ->(i : Int32) { received = i; nil }
      il.select(1)
      received.should eq(1)
    end

    it "safe with no callback" do
      screen = test_screen
      il = CRT::ItemList.new(screen, x: 0, y: 0, items: ["A", "B"])
      il.select(1) # should not raise
    end
  end
end
