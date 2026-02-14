require "../spec_helper"

describe CRT::Screen do
  describe "construction" do
    it "creates with IO::Memory" do
      screen = test_screen
      screen.width.should eq(80)
      screen.height.should eq(24)
    end
  end

  describe "#register / #unregister" do
    it "tracks widgets" do
      screen = test_screen
      w1 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      w2 = TestWidget.new(screen, x: 10, y: 0, width: 10, height: 5)
      screen.widgets.size.should eq(2)
      screen.unregister(w1)
      screen.widgets.size.should eq(1)
      screen.widgets.should contain(w2)
    end

    it "does not register duplicates" do
      screen = test_screen
      widget = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      screen.register(widget) # already registered by constructor
      screen.widgets.size.should eq(1)
    end
  end

  describe "#raise / #lower" do
    it "moves widget to top" do
      screen = test_screen
      w1 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      w2 = TestWidget.new(screen, x: 10, y: 0, width: 10, height: 5)
      screen.widgets.last.should eq(w2)
      screen.raise(w1)
      screen.widgets.last.should eq(w1)
    end

    it "moves widget to bottom" do
      screen = test_screen
      w1 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      w2 = TestWidget.new(screen, x: 10, y: 0, width: 10, height: 5)
      screen.widgets.first.should eq(w1)
      screen.lower(w2)
      screen.widgets.first.should eq(w2)
    end
  end

  describe "focus management" do
    it "starts with no focused widget" do
      screen = test_screen
      screen.focused_widget.should be_nil
    end

    it "focuses a focusable widget" do
      screen = test_screen
      widget = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      screen.focus(widget)
      screen.focused_widget.should eq(widget)
      widget.focused?.should be_true
    end

    it "refuses to focus a non-focusable widget" do
      screen = test_screen
      widget = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      screen.focus(widget)
      screen.focused_widget.should be_nil
    end

    it "refuses to focus a hidden widget" do
      screen = test_screen
      widget = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      widget.hide
      screen.focus(widget)
      screen.focused_widget.should be_nil
    end

    it "unfocuses previous widget when focusing new one" do
      screen = test_screen
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      w2 = FocusableWidget.new(screen, x: 10, y: 0, width: 10, height: 5)
      screen.focus(w1)
      w1.focused?.should be_true
      screen.focus(w2)
      w1.focused?.should be_false
      w2.focused?.should be_true
    end

    it "clears focus when focused widget is unregistered" do
      screen = test_screen
      widget = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      screen.focus(widget)
      screen.focused_widget.should eq(widget)
      widget.destroy
      screen.focused_widget.should be_nil
    end
  end

  describe "#focus_next / #focus_prev" do
    it "cycles through focusable widgets" do
      screen = test_screen
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      _nf = TestWidget.new(screen, x: 20, y: 0, width: 10, height: 5)  # not focusable
      w2 = FocusableWidget.new(screen, x: 30, y: 0, width: 10, height: 5)

      screen.focus_next
      screen.focused_widget.should eq(w1)

      screen.focus_next
      screen.focused_widget.should eq(w2)

      screen.focus_next
      screen.focused_widget.should eq(w1)  # wraps around
    end

    it "cycles backwards with focus_prev" do
      screen = test_screen
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      w2 = FocusableWidget.new(screen, x: 10, y: 0, width: 10, height: 5)

      screen.focus_prev
      screen.focused_widget.should eq(w2)  # starts from end

      screen.focus_prev
      screen.focused_widget.should eq(w1)
    end

    it "skips hidden focusable widgets" do
      screen = test_screen
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      w2 = FocusableWidget.new(screen, x: 10, y: 0, width: 10, height: 5)
      w3 = FocusableWidget.new(screen, x: 20, y: 0, width: 10, height: 5)

      w2.hide
      screen.focus_next
      screen.focused_widget.should eq(w1)
      screen.focus_next
      screen.focused_widget.should eq(w3)  # skips w2
    end

    it "does nothing when no focusable widgets exist" do
      screen = test_screen
      TestWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      screen.focus_next
      screen.focused_widget.should be_nil
    end
  end

  describe "#dispatch" do
    it "routes Tab to focus_next" do
      screen = test_screen
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      w2 = FocusableWidget.new(screen, x: 10, y: 0, width: 10, height: 5)

      tab = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab)
      screen.dispatch(tab).should be_true
      screen.focused_widget.should eq(w1)
      screen.dispatch(tab).should be_true
      screen.focused_widget.should eq(w2)
    end

    it "routes Shift+Tab to focus_prev" do
      screen = test_screen
      w1 = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      _w2 = FocusableWidget.new(screen, x: 10, y: 0, width: 10, height: 5)

      shift_tab = CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab, shift: true)
      screen.dispatch(shift_tab).should be_true
      screen.focused_widget.should eq(_w2)  # starts from end
    end

    it "routes other events to focused widget" do
      screen = test_screen
      widget = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      screen.focus(widget)

      key = CRT::Ansi::Key.char('a')
      screen.dispatch(key).should be_true
      widget.last_event.should eq(key)
    end

    it "returns false when no widget is focused" do
      screen = test_screen
      key = CRT::Ansi::Key.char('a')
      screen.dispatch(key).should be_false
    end
  end

  describe "#draw" do
    it "calls draw on visible widgets" do
      screen = test_screen
      w1 = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      w2 = TestWidget.new(screen, x: 10, y: 0, width: 10, height: 5)
      w2.hide

      screen.draw

      w1.draw_count.should eq(1)
      w2.draw_count.should eq(0)
    end
  end

  describe "#center_x / #center_y" do
    it "calculates centered position" do
      screen = test_screen  # 80x24
      screen.center_x(20).should eq(30)
      screen.center_y(10).should eq(7)
    end
  end
end
