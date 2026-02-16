require "../../spec_helper"

describe CRT::ListBox do
  describe "construction" do
    it "is focusable by default" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      lb.focusable?.should be_true
    end

    it "selected defaults to 0" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      lb.selected.should eq(0)
    end

    it "auto-sizes width from items" do
      screen = test_screen
      # "▸ Long Option" = 1 + 1 + 11 = 13 + border 2 = 15
      lb = CRT::ListBox.new(screen, x: 0, y: 0,
        items: ["Short", "Long Option", "Mid"])
      lb.width.should eq(15)
    end

    it "auto-sizes height from item count + border" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      lb.height.should eq(5) # 3 items + 2 border
    end

    it "auto-sizes without border" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0,
        items: ["A", "B"], border: nil)
      lb.height.should eq(2)
    end

    it "uses explicit width and height" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0,
        items: ["A", "B", "C"], width: 30, height: 5)
      lb.width.should eq(30)
      lb.height.should eq(5)
    end

    it "default border is Single" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B"])
      lb.border.should eq(CRT::Ansi::Border::Single)
    end
  end

  describe "selection" do
    it "selected= updates and clamps" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      lb.selected = 2
      lb.selected.should eq(2)
      lb.selected = 10
      lb.selected.should eq(2)
      lb.selected = -1
      lb.selected.should eq(0)
    end

    it "selected_item returns correct string" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      lb.selected_item.should eq("A")
      lb.selected = 2
      lb.selected_item.should eq("C")
    end

    it "Down changes selection" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      lb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down))
      lb.selected.should eq(1)
    end

    it "Up changes selection" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B", "C"],
        selected: 2)
      lb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Up))
      lb.selected.should eq(1)
    end

    it "Up at 0 stays at 0" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      lb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Up))
      lb.selected.should eq(0)
    end

    it "Down at last stays at last" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B", "C"],
        selected: 2)
      lb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down))
      lb.selected.should eq(2)
    end

    it "Home selects first" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B", "C"],
        selected: 2)
      lb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Home))
      lb.selected.should eq(0)
    end

    it "End selects last" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      lb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::End))
      lb.selected.should eq(2)
    end

    it "callback fires on change" do
      screen = test_screen
      received = nil
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B", "C"]) { |i|
        received = i
      }
      lb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down))
      received.should eq(1)
    end

    it "callback does not fire when selecting same index" do
      screen = test_screen
      called = 0
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B", "C"]) { |_|
        called += 1
      }
      lb.select(0) # already at 0
      called.should eq(0)
    end
  end

  describe "scrolling" do
    it "no scroll needed when all items fit" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      lb.scroll_y.should eq(0)
    end

    it "Down past visible area scrolls down" do
      screen = test_screen
      # height 5 = 3 visible + 2 border
      lb = CRT::ListBox.new(screen, x: 0, y: 0,
        items: ["A", "B", "C", "D", "E", "F"], height: 5)
      3.times { lb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down)) }
      # selected=3, visible=3 (rows 0-2), should scroll to show item 3
      lb.selected.should eq(3)
      lb.scroll_y.should eq(1)
    end

    it "Up past visible area scrolls up" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0,
        items: ["A", "B", "C", "D", "E", "F"], height: 5, selected: 5)
      # selected=5, scroll_y should be 3 (showing items 3,4,5)
      lb.scroll_y.should eq(3)
      5.times { lb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Up)) }
      lb.selected.should eq(0)
      lb.scroll_y.should eq(0)
    end

    it "Home scrolls to top" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0,
        items: ["A", "B", "C", "D", "E", "F"], height: 5, selected: 5)
      lb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Home))
      lb.selected.should eq(0)
      lb.scroll_y.should eq(0)
    end

    it "End scrolls to bottom" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0,
        items: ["A", "B", "C", "D", "E", "F"], height: 5)
      lb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::End))
      lb.selected.should eq(5)
      lb.scroll_y.should eq(3) # 6 items - 3 visible = 3
    end
  end

  describe "#draw" do
    it "renders marker on selected row" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B"])
      screen.draw

      render = screen.ansi.render
      # Row 0 inside border (y=1): "▸ A"
      render.cell(1, 1).grapheme.should eq("▸")
      render.cell(3, 1).grapheme.should eq("A")
      # Row 1 inside border (y=2): "  B"
      render.cell(1, 2).grapheme.should eq(" ")
      render.cell(3, 2).grapheme.should eq("B")
    end

    it "applies field_focus style to selected row when focused" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B"])
      screen.focus(lb)
      screen.draw

      render = screen.ansi.render
      render.cell(1, 1).style.bg.should eq(CRT.theme.bright)  # selected row
      render.cell(1, 2).style.bg.should eq(CRT.theme.bg)       # unselected row
    end

    it "selected uses field style when unfocused" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B"])
      screen.draw

      render = screen.ansi.render
      render.cell(1, 1).style.bg.should eq(CRT.theme.fg)
    end

    it "renders only visible items when scrolled" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0,
        items: ["A", "B", "C", "D", "E"], height: 4) # 2 visible rows
      lb.selected = 3  # scrolls to show item 3
      screen.draw

      render = screen.ansi.render
      # With scroll_y=2, visible items are C(2) and D(3)
      render.cell(3, 1).grapheme.should eq("C")
      render.cell(3, 2).grapheme.should eq("D")
    end
  end

  describe "#handle_event" do
    it "Space fires callback" do
      screen = test_screen
      received = nil
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B"]) { |i|
        received = i
      }
      lb.handle_event(CRT::Ansi::Key.char(' ')).should be_true
      received.should eq(0)
    end

    it "Enter fires callback" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B"])
      lb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Enter)).should be_true
    end

    it "mouse click selects clicked item" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B", "C"])
      # content_y = 1 (border), so clicking y=2 → item index 1
      click = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Left,
        CRT::Ansi::Mouse::Action::Press, 2, 2)
      lb.handle_event(click).should be_true
      lb.selected.should eq(1)
    end

    it "mouse click accounts for scroll" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0,
        items: ["A", "B", "C", "D", "E"], height: 4) # 2 visible
      lb.selected = 3  # scroll_y = 2
      # Click y=1 (first visible row) → item index = (1 - 1) + 2 = 2
      click = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Left,
        CRT::Ansi::Mouse::Action::Press, 2, 1)
      lb.handle_event(click).should be_true
      lb.selected.should eq(2)
    end

    it "mouse click outside returns false" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B"])
      click = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Left,
        CRT::Ansi::Mouse::Action::Press, 30, 30)
      lb.handle_event(click).should be_false
    end

    it "other keys return false" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B"])
      lb.handle_event(CRT::Ansi::Key.char('a')).should be_false
    end
  end

  describe "callback" do
    it "on_change= setter works" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B"])
      received = nil
      lb.on_change = ->(i : Int32) { received = i; nil }
      lb.select(1)
      received.should eq(1)
    end

    it "safe with no callback" do
      screen = test_screen
      lb = CRT::ListBox.new(screen, x: 0, y: 0, items: ["A", "B"])
      lb.select(1) # should not raise
    end
  end
end
