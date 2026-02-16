require "../../spec_helper"

describe CRT::Frame do
  describe "construction" do
    it "creates with explicit size" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 20, height: 10)
      frame.width.should eq(20)
      frame.height.should eq(10)
      frame.children.should be_empty
    end

    it "defaults to column direction" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 20, height: 10)
      frame.children.should be_empty
    end

    it "registers with screen" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 20, height: 10)
      screen.widgets.should contain(frame)
    end

    it "is focusable" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 20, height: 10)
      frame.focusable?.should be_true
    end
  end

  describe "#add" do
    it "moves widget from screen to frame" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 40, height: 20)
      label = CRT::Label.new(screen, x: 0, y: 0, text: "Hello")
      screen.widgets.should contain(label)

      frame.add(label)
      screen.widgets.should_not contain(label)
      frame.children.should contain(label)
    end

    it "positions child in column layout" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 5, y: 3, width: 20, height: 10)
      w1 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      w2 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 3)

      frame.add(w1)
      frame.add(w2)

      w1.x.should eq(5)
      w1.y.should eq(3)
      w2.x.should eq(5)
      w2.y.should eq(5) # 3 + 2
    end

    it "positions child in row layout" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 5, y: 3, width: 40, height: 10,
        direction: CRT::Direction::Row)
      w1 = TestWidget.new(screen, x: 0, y: 0, width: 8, height: 2)
      w2 = TestWidget.new(screen, x: 0, y: 0, width: 12, height: 3)

      frame.add(w1)
      frame.add(w2)

      w1.x.should eq(5)
      w1.y.should eq(3)
      w2.x.should eq(13) # 5 + 8
      w2.y.should eq(3)
    end

    it "applies gap between children" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 20, height: 20, gap: 1)
      w1 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      w2 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 2)

      frame.add(w1)
      frame.add(w2)

      w1.y.should eq(0)
      w2.y.should eq(3) # 0 + 2 + 1 gap
    end

    it "insets children by border" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 20, height: 10,
        border: CRT::Border::Single)
      w1 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 2)

      frame.add(w1)

      w1.x.should eq(1) # content_x = 0 + 1
      w1.y.should eq(1) # content_y = 0 + 1
    end

    it "chains with <<" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 20, height: 20)
      w1 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      w2 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 3)

      frame << w1 << w2

      frame.children.size.should eq(2)
    end
  end

  describe "auto-sizing" do
    it "auto-sizes column from children" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0)
      w1 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      w2 = TestWidget.new(screen, x: 0, y: 0, width: 15, height: 3)

      frame << w1 << w2

      frame.width.should eq(15)  # max child width
      frame.height.should eq(5)  # 2 + 3
    end

    it "auto-sizes row from children" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0,
        direction: CRT::Direction::Row)
      w1 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      w2 = TestWidget.new(screen, x: 0, y: 0, width: 15, height: 3)

      frame << w1 << w2

      frame.width.should eq(25)  # 10 + 15
      frame.height.should eq(3)  # max child height
    end

    it "includes gap in auto-size" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, gap: 1)
      w1 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      w2 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 2)

      frame << w1 << w2

      frame.height.should eq(5) # 2 + 1 + 2
    end

    it "includes border inset in auto-size" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0,
        border: CRT::Border::Single)
      w1 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 2)

      frame << w1

      frame.width.should eq(12)  # 10 + 2
      frame.height.should eq(4)  # 2 + 2
    end
  end

  describe "#remove" do
    it "removes child and relayouts" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 20, height: 20)
      w1 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      w2 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 3)

      frame << w1 << w2
      frame.remove(w1)

      frame.children.size.should eq(1)
      w2.y.should eq(0) # relaid out to top
    end
  end

  describe "#draw" do
    it "draws children" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 20, height: 10)
      w1 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      frame << w1

      io = IO::Memory.new
      render = CRT::Ansi::Render.new(io, 20, 10)
      frame.draw(render)

      w1.draw_count.should eq(1)
    end

    it "draws title on border via overlay" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 20, height: 10,
        border: CRT::Border::Single, title: "Test")

      io = IO::Memory.new
      render = CRT::Ansi::Render.new(io, 20, 10)
      frame.draw(render)
      frame.draw_overlay(render)

      # Title " Test " should appear on top row (leading space at x=2)
      render.cell(3, 0).grapheme.should eq("T")
      render.cell(4, 0).grapheme.should eq("e")
      render.cell(5, 0).grapheme.should eq("s")
      render.cell(6, 0).grapheme.should eq("t")
    end
  end

  describe "focus cycling" do
    it "focuses first child when frame gains focus" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 40, height: 20)
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      w2 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      frame << w1 << w2

      screen.focus(frame)

      frame.focused?.should be_true
      frame.focused_child.should eq(w1)
      w1.focused?.should be_true
    end

    it "cycles to next child on Tab" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 40, height: 20)
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      w2 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      frame << w1 << w2
      screen.focus(frame)

      tab = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab)
      result = frame.handle_event(tab)

      result.should be_true
      frame.focused_child.should eq(w2)
      w2.focused?.should be_true
      w1.focused?.should be_false
    end

    it "returns false when Tab past last child" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 40, height: 20)
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      frame << w1
      screen.focus(frame)

      tab = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab)
      result = frame.handle_event(tab)

      result.should be_false
    end

    it "cycles backward on Shift+Tab" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 40, height: 20)
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      w2 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      frame << w1 << w2
      screen.focus(frame)

      # Move to w2 first
      tab = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab)
      frame.handle_event(tab)
      frame.focused_child.should eq(w2)

      # Shift+Tab back to w1
      shift_tab = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab, shift: true)
      result = frame.handle_event(shift_tab)

      result.should be_true
      frame.focused_child.should eq(w1)
    end

    it "unfocuses child when frame loses focus" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 40, height: 20)
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      frame << w1
      screen.focus(frame)
      w1.focused?.should be_true

      frame.unfocus
      w1.focused?.should be_false
    end

    it "forwards non-Tab events to focused child" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 40, height: 20)
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      frame << w1
      screen.focus(frame)

      key = CRT::Ansi::Key.char('a')
      frame.handle_event(key)

      w1.last_event.should eq(key)
    end
  end

  describe "#destroy" do
    it "destroys all children" do
      screen = test_screen
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 40, height: 20)
      w1 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      w2 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      frame << w1 << w2

      frame.destroy
      frame.children.should be_empty
      screen.widgets.should_not contain(frame)
    end
  end

  describe "boxing integration" do
    it "insets children by boxing border" do
      screen = test_screen
      boxing = CRT::Boxing.new
      frame = CRT::Frame.new(screen, x: 0, y: 0, width: 20, height: 10,
        box: boxing)
      w1 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 2)
      frame << w1

      # Boxing implies border inset
      w1.x.should eq(1)
      w1.y.should eq(1)
    end

    it "registers with boxing" do
      screen = test_screen
      boxing = CRT::Boxing.new
      CRT::Frame.new(screen, x: 0, y: 0, width: 20, height: 10, box: boxing)

      boxing.edges_at(0, 0).should_not eq(CRT::Ansi::Boxing::Edge::None)
    end
  end
end
