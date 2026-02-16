require "../spec_helper"

describe CRT::Widget do
  describe "construction" do
    it "registers with screen" do
      screen = test_screen
      widget = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      screen.widgets.should contain(widget)
    end

    it "stores position and size" do
      screen = test_screen
      widget = TestWidget.new(screen, x: 3, y: 7, width: 20, height: 10)
      widget.x.should eq(3)
      widget.y.should eq(7)
      widget.width.should eq(20)
      widget.height.should eq(10)
    end

    it "defaults to visible, not focusable, not focused" do
      screen = test_screen
      widget = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      widget.visible?.should be_true
      widget.focusable?.should be_false
      widget.focused?.should be_false
    end

    it "defaults to no border and no shadow" do
      screen = test_screen
      widget = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      widget.border.should be_nil
      widget.shadow.should be_false
    end
  end

  describe "#destroy" do
    it "unregisters from screen" do
      screen = test_screen
      widget = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      screen.widgets.should contain(widget)
      widget.destroy
      screen.widgets.should_not contain(widget)
    end
  end

  describe ".open" do
    it "yields widget and destroys on block exit" do
      screen = test_screen
      captured = nil
      TestWidget.open(screen, x: 0, y: 0, width: 10, height: 5) do |w|
        captured = w
        screen.widgets.should contain(w)
      end
      screen.widgets.should_not contain(captured)
    end
  end

  describe "#show / #hide" do
    it "toggles visibility" do
      screen = test_screen
      widget = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      widget.visible?.should be_true
      widget.hide
      widget.visible?.should be_false
      widget.show
      widget.visible?.should be_true
    end
  end

  describe "#focus / #unfocus" do
    it "toggles focused state" do
      screen = test_screen
      widget = FocusableWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      widget.focused?.should be_false
      widget.focus
      widget.focused?.should be_true
      widget.unfocus
      widget.focused?.should be_false
    end
  end

  describe "content area helpers" do
    it "returns full area without border" do
      screen = test_screen
      widget = TestWidget.new(screen, x: 5, y: 3, width: 20, height: 10)
      widget.content_x.should eq(5)
      widget.content_y.should eq(3)
      widget.content_width.should eq(20)
      widget.content_height.should eq(10)
    end

    it "insets by 1 with border" do
      screen = test_screen
      widget = TestWidget.new(screen, x: 5, y: 3, width: 20, height: 10,
        border: CRT::Ansi::Border::Single)
      widget.content_x.should eq(6)
      widget.content_y.should eq(4)
      widget.content_width.should eq(18)
      widget.content_height.should eq(8)
    end

    it "insets by 1 with box (border nil)" do
      screen = test_screen
      boxing = CRT::Ansi::Boxing.new
      widget = TestWidget.new(screen, x: 5, y: 3, width: 20, height: 10, box: boxing)
      widget.content_x.should eq(6)
      widget.content_y.should eq(4)
      widget.content_width.should eq(18)
      widget.content_height.should eq(8)
    end

    it "no inset with box and border None" do
      screen = test_screen
      boxing = CRT::Ansi::Boxing.new
      widget = TestWidget.new(screen, x: 5, y: 3, width: 20, height: 10,
        box: boxing, border: CRT::Ansi::Border::None)
      widget.content_x.should eq(5)
      widget.content_y.should eq(3)
      widget.content_width.should eq(20)
      widget.content_height.should eq(10)
    end
  end

  describe "#hit?" do
    it "returns true when point is inside widget bounds" do
      screen = test_screen
      widget = TestWidget.new(screen, x: 5, y: 3, width: 10, height: 5)
      widget.hit?(5, 3).should be_true
      widget.hit?(10, 5).should be_true
      widget.hit?(14, 7).should be_true
    end

    it "returns false when point is outside widget bounds" do
      screen = test_screen
      widget = TestWidget.new(screen, x: 5, y: 3, width: 10, height: 5)
      widget.hit?(4, 3).should be_false    # left of
      widget.hit?(15, 3).should be_false   # right of (x + width)
      widget.hit?(5, 2).should be_false    # above
      widget.hit?(5, 8).should be_false    # below (y + height)
    end
  end

  describe "#handle_event" do
    it "returns false by default" do
      screen = test_screen
      widget = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      event = CRT::Ansi::Key.char('a')
      widget.handle_event(event).should be_false
    end
  end

  describe "boxing integration" do
    it "registers with boxing on construction" do
      screen = test_screen
      boxing = CRT::Ansi::Boxing.new
      TestWidget.new(screen, x: 2, y: 3, width: 10, height: 5, box: boxing)
      boxing.width.should eq(12)
      boxing.height.should eq(8)
      boxing.edges_at(2, 3).should eq(
        CRT::Ansi::Boxing::Edge::Right | CRT::Ansi::Boxing::Edge::Down
      )
    end

    it "does not register with boxing when border is None" do
      screen = test_screen
      boxing = CRT::Ansi::Boxing.new
      TestWidget.new(screen, x: 2, y: 3, width: 10, height: 5,
        box: boxing, border: CRT::Ansi::Border::None)
      boxing.width.should eq(0)
      boxing.height.should eq(0)
    end

    it "unregisters from boxing on destroy" do
      screen = test_screen
      boxing = CRT::Ansi::Boxing.new
      w = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 5, box: boxing)
      boxing.edges_at(0, 0).should_not eq(CRT::Ansi::Boxing::Edge::None)
      w.destroy
      boxing.edges_at(0, 0).should eq(CRT::Ansi::Boxing::Edge::None)
    end

    it "tracks boxing on screen" do
      screen = test_screen
      boxing = CRT::Ansi::Boxing.new
      TestWidget.new(screen, x: 0, y: 0, width: 10, height: 5, box: boxing)
      # Boxing should be drawn during screen draw (no crash = success)
      screen.draw
    end

    it "adjacent widgets share boxing intersections" do
      screen = test_screen
      boxing = CRT::Ansi::Boxing.new
      TestWidget.new(screen, x: 0, y: 0, width: 6, height: 3, box: boxing)
      TestWidget.new(screen, x: 5, y: 0, width: 6, height: 3, box: boxing)
      # Shared edge creates T-junction
      edge = boxing.edges_at(5, 0)
      edge.left?.should be_true
      edge.right?.should be_true
      edge.down?.should be_true
    end
  end
end
