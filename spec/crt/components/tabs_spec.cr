require "../../spec_helper"

describe CRT::Tabs do
  describe "construction" do
    it "creates with given size" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      tabs.width.should eq(40)
      tabs.height.should eq(15)
      tabs.pages.should be_empty
      tabs.active.should eq(0)
    end

    it "registers with screen" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      screen.widgets.should contain(tabs)
    end

    it "is focusable" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      tabs.focusable?.should be_true
    end

    it "accepts custom theme" do
      screen = test_screen
      t = CRT::Theme.new(
        bg: CRT::Color.rgb(0, 0, 0),
        fg: CRT::Color.rgb(200, 200, 200))
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      tabs.pages.should be_empty
      tabs.theme.should eq(CRT.theme)
    end
  end

  describe "#add" do
    it "creates a page and returns its frame" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      frame = tabs.add("Tab 1")

      tabs.pages.size.should eq(1)
      tabs.pages[0].label.should eq("Tab 1")
      frame.should be_a(CRT::Frame)
    end

    it "does not register page frame with screen" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      frame = tabs.add("Tab 1")

      screen.widgets.should_not contain(frame)
    end

    it "positions page frame in content area below tab bar and separator" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 5, y: 3, width: 40, height: 15,
        border: CRT::Border::Single, separator: true)
      frame = tabs.add("Tab 1")

      # content_x = 5 + 1 = 6, +1 padding = 7
      # content_y = 3 + 1 = 4, +2 (tab bar + padding) + 1 (separator) = 7
      frame.x.should eq(8)
      frame.y.should eq(7)
      # page_width = content_width - 2 = 38 - 2 = 36
      frame.width.should eq(36)
      # page_height = content_height - 2 - 1 = 13 - 3 = 10
      frame.height.should eq(10)
    end

    it "positions page frame without separator" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15,
        separator: false)
      frame = tabs.add("Tab 1")

      # No border, no separator: page_x = 0 + 1, page_y = 0 + 2
      frame.x.should eq(2)
      frame.y.should eq(2)
      frame.width.should eq(38)
      frame.height.should eq(13) # 15 - 2
    end

    it "first page becomes active" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      tabs.add("First")
      tabs.add("Second")

      tabs.active.should eq(0)
    end
  end

  describe "#active=" do
    it "switches active tab" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      tabs.add("Tab 1")
      tabs.add("Tab 2")

      tabs.active = 1
      tabs.active.should eq(1)
    end

    it "ignores out-of-bounds index" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      tabs.add("Tab 1")

      tabs.active = 5
      tabs.active.should eq(0)

      tabs.active = -1
      tabs.active.should eq(0)
    end
  end

  describe "#active_page" do
    it "returns the active page frame" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      f1 = tabs.add("Tab 1")
      f2 = tabs.add("Tab 2")

      tabs.active_page.should eq(f1)
      tabs.active = 1
      tabs.active_page.should eq(f2)
    end

    it "returns nil with no pages" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      tabs.active_page.should be_nil
    end
  end

  describe "#draw" do
    it "draws tab bar text" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 10)
      tabs.add("Alpha")
      tabs.add("Beta")

      io = IO::Memory.new
      render = CRT::Ansi::Render.new(io, 40, 10)
      tabs.draw(render)

      # Active tab: " Alpha " starting at x=0
      render.cell(0, 0).grapheme.should eq(" ")
      render.cell(1, 0).grapheme.should eq("A")
      render.cell(2, 0).grapheme.should eq("l")
    end

    it "draws separator line" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 20, height: 10,
        border: CRT::Border::Single, separator: true)
      tabs.add("Tab")

      io = IO::Memory.new
      render = CRT::Ansi::Render.new(io, 20, 10)
      tabs.draw(render)

      # Separator at y = content_y + 1 = 1 + 1 = 2
      # Left tee at x=0, right tee at x=19
      render.cell(0, 2).grapheme.should eq("├")
      render.cell(19, 2).grapheme.should eq("┤")
      render.cell(1, 2).grapheme.should eq("─")
    end

    it "only draws active page content" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      f1 = tabs.add("Tab 1")
      f2 = tabs.add("Tab 2")

      w1 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 1)
      f1 << w1
      w2 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 1)
      f2 << w2

      io = IO::Memory.new
      render = CRT::Ansi::Render.new(io, 40, 15)
      tabs.draw(render)

      w1.draw_count.should eq(1)
      w2.draw_count.should eq(0)

      tabs.active = 1
      tabs.draw(render)

      w2.draw_count.should eq(1)
    end

    it "does not draw separator when disabled" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 20, height: 10,
        border: CRT::Border::Single, separator: false)
      tabs.add("Tab")

      io = IO::Memory.new
      render = CRT::Ansi::Render.new(io, 20, 10)
      tabs.draw(render)

      # No separator at y=2, should still show fill (space)
      render.cell(0, 2).grapheme.should_not eq("├")
    end
  end

  describe "tab bar navigation" do
    it "switches tab with Right arrow" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      tabs.add("Tab 1")
      tabs.add("Tab 2")
      screen.focus(tabs)

      right = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Right)
      result = tabs.handle_event(right)

      result.should be_true
      tabs.active.should eq(1)
    end

    it "switches tab with Left arrow" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      tabs.add("Tab 1")
      tabs.add("Tab 2")
      tabs.active = 1
      screen.focus(tabs)

      left = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Left)
      result = tabs.handle_event(left)

      result.should be_true
      tabs.active.should eq(0)
    end

    it "clamps at first tab on Left" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      tabs.add("Tab 1")
      tabs.add("Tab 2")
      screen.focus(tabs)

      left = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Left)
      tabs.handle_event(left)

      tabs.active.should eq(0)
    end

    it "clamps at last tab on Right" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      tabs.add("Tab 1")
      tabs.add("Tab 2")
      tabs.active = 1
      screen.focus(tabs)

      right = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Right)
      tabs.handle_event(right)

      tabs.active.should eq(1)
    end
  end

  describe "focus: tab bar to page" do
    it "Tab enters active page" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      f1 = tabs.add("Tab 1")
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      f1 << w1
      screen.focus(tabs)

      tab = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab)
      result = tabs.handle_event(tab)

      result.should be_true
      w1.focused?.should be_true
    end

    it "Tab exits Tabs when page has no focusable children" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      f1 = tabs.add("Tab 1")
      # Only add a non-focusable Label
      CRT::Label.new(screen, x: 0, y: 0, text: "Info").tap { |w| f1 << w }
      screen.focus(tabs)

      tab = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab)
      result = tabs.handle_event(tab)

      result.should be_false
    end

    it "Shift+Tab from tab bar exits Tabs" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      tabs.add("Tab 1")
      screen.focus(tabs)

      shift_tab = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab, shift: true)
      result = tabs.handle_event(shift_tab)

      result.should be_false
    end
  end

  describe "focus: within page" do
    it "Tab cycles through page children" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      f1 = tabs.add("Tab 1")
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      w2 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      f1 << w1 << w2
      screen.focus(tabs)

      tab = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab)
      # Enter page
      tabs.handle_event(tab)
      w1.focused?.should be_true

      # Cycle to w2
      tabs.handle_event(tab)
      w2.focused?.should be_true
      w1.focused?.should be_false
    end

    it "Tab past last child exits Tabs forward" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      f1 = tabs.add("Tab 1")
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      f1 << w1
      screen.focus(tabs)

      tab = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab)
      # Enter page (focuses w1)
      tabs.handle_event(tab)
      w1.focused?.should be_true

      # Tab again — past last child, exits Tabs
      result = tabs.handle_event(tab)
      result.should be_false
    end

    it "Shift+Tab from first child returns to tab bar" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      f1 = tabs.add("Tab 1")
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      w2 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      f1 << w1 << w2
      screen.focus(tabs)

      tab = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab)
      # Enter page
      tabs.handle_event(tab)
      w1.focused?.should be_true

      # Shift+Tab — past first child, back to tab bar
      shift_tab = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab, shift: true)
      result = tabs.handle_event(shift_tab)

      result.should be_true
      w1.focused?.should be_false
    end

    it "forwards non-Tab keys to page" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      f1 = tabs.add("Tab 1")
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      f1 << w1
      screen.focus(tabs)

      # Enter page
      tab = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab)
      tabs.handle_event(tab)

      # Send a key
      key = CRT::Ansi::Key.char('x')
      result = tabs.handle_event(key)

      result.should be_true
      w1.last_event.should eq(key)
    end
  end

  describe "tab switching with focus" do
    it "unfocuses old page when switching tabs while in page" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      f1 = tabs.add("Tab 1")
      f2 = tabs.add("Tab 2")
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      f1 << w1
      w2 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      f2 << w2

      screen.focus(tabs)
      # Enter page
      tab = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab)
      tabs.handle_event(tab)
      w1.focused?.should be_true

      # Switch tab while in page
      tabs.active = 1
      w1.focused?.should be_false
    end
  end

  describe "#unfocus" do
    it "unfocuses active page" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      f1 = tabs.add("Tab 1")
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      f1 << w1

      screen.focus(tabs)
      tab = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab)
      tabs.handle_event(tab)
      w1.focused?.should be_true

      tabs.unfocus
      w1.focused?.should be_false
      tabs.focused?.should be_false
    end
  end

  describe "#destroy" do
    it "destroys all page frames" do
      screen = test_screen
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15)
      tabs.add("Tab 1")
      tabs.add("Tab 2")

      tabs.destroy
      tabs.pages.should be_empty
      screen.widgets.should_not contain(tabs)
    end
  end

  describe "boxing integration" do
    it "works with box parameter" do
      screen = test_screen
      boxing = CRT::Boxing.new
      tabs = CRT::Tabs.new(screen, x: 0, y: 0, width: 40, height: 15,
        box: boxing)

      tabs.add("Tab 1")
      boxing.edges_at(0, 0).should_not eq(CRT::Ansi::Boxing::Edge::None)
    end
  end
end
