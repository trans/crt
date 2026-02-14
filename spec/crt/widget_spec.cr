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
  end

  describe "#handle_event" do
    it "returns false by default" do
      screen = test_screen
      widget = TestWidget.new(screen, x: 0, y: 0, width: 10, height: 5)
      event = CRT::Ansi::Key.char('a')
      widget.handle_event(event).should be_false
    end
  end
end
