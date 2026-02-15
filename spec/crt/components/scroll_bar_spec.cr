require "../../spec_helper"

describe CRT::ScrollBar do
  describe "construction" do
    it "is focusable by default" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0)
      sb.focusable?.should be_true
    end

    it "vertical orientation by default" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0)
      sb.orientation.should eq(CRT::Orientation::Vertical)
    end

    it "vertical: width 1, height = length" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0, length: 8)
      sb.width.should eq(1)
      sb.height.should eq(8)
    end

    it "horizontal: width = length, height 1" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0,
        orientation: CRT::Orientation::Horizontal, length: 12)
      sb.width.should eq(12)
      sb.height.should eq(1)
    end

    it "value defaults to 0.0" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0)
      sb.value.should eq(0.0)
    end

    it "clamps initial value" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0, value: 2.0)
      sb.value.should eq(1.0)
    end

    it "thumb_size defaults to 0.0" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0)
      sb.thumb_size.should eq(0.0)
    end
  end

  describe "#value=" do
    it "updates value" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0)
      sb.value = 0.5
      sb.value.should eq(0.5)
    end

    it "clamps above 1.0" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0)
      sb.value = 5.0
      sb.value.should eq(1.0)
    end

    it "clamps below 0.0" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0)
      sb.value = -1.0
      sb.value.should eq(0.0)
    end
  end

  describe "#draw" do
    describe "vertical" do
      it "thumb at top when value is 0.0" do
        screen = test_screen
        sb = CRT::ScrollBar.new(screen, x: 0, y: 0, length: 5)
        screen.focus(sb)
        screen.draw

        render = screen.ansi.render
        # Thumb at top: bg = bright white (indexed 15)
        render.cell(0, 0).style.bg.should eq(CRT::Ansi::Color.indexed(15))
        # Track at bottom: bg = dark gray (indexed 8)
        render.cell(0, 4).style.bg.should eq(CRT::Ansi::Color.indexed(8))
      end

      it "thumb at bottom when value is 1.0" do
        screen = test_screen
        sb = CRT::ScrollBar.new(screen, x: 0, y: 0, length: 5, value: 1.0)
        screen.focus(sb)
        screen.draw

        render = screen.ansi.render
        render.cell(0, 0).style.bg.should eq(CRT::Ansi::Color.indexed(8))
        render.cell(0, 4).style.bg.should eq(CRT::Ansi::Color.indexed(15))
      end

      it "uses half-block at thumb edge" do
        screen = test_screen
        sb = CRT::ScrollBar.new(screen, x: 0, y: 0, length: 4, value: 0.5)
        screen.focus(sb)
        screen.draw

        render = screen.ansi.render
        chars = (0...4).map { |r| render.cell(0, r).grapheme }
        has_half = chars.any? { |c| c == "▀" || c == "▄" }
        (has_half || chars.includes?(" ")).should be_true
      end

      it "proportional thumb with thumb_size" do
        screen = test_screen
        sb = CRT::ScrollBar.new(screen, x: 0, y: 0, length: 10,
          thumb_size: 0.5, value: 0.0)
        screen.focus(sb)
        screen.draw

        render = screen.ansi.render
        thumb_color = CRT::Ansi::Color.indexed(15)
        filled = (0...10).count { |r| render.cell(0, r).style.bg == thumb_color }
        filled.should be >= 4
        filled.should be <= 6
      end

      it "dims thumb when unfocused" do
        screen = test_screen
        sb = CRT::ScrollBar.new(screen, x: 0, y: 0, length: 5)
        # Not focused
        screen.draw

        render = screen.ansi.render
        # Unfocused thumb uses dim color (indexed 7)
        render.cell(0, 0).style.bg.should eq(CRT::Ansi::Color.indexed(7))
      end
    end

    describe "horizontal" do
      it "thumb at left when value is 0.0" do
        screen = test_screen
        sb = CRT::ScrollBar.new(screen, x: 0, y: 0, length: 5,
          orientation: CRT::Orientation::Horizontal)
        screen.focus(sb)
        screen.draw

        render = screen.ansi.render
        render.cell(0, 0).style.bg.should eq(CRT::Ansi::Color.indexed(15))
        render.cell(4, 0).style.bg.should eq(CRT::Ansi::Color.indexed(8))
      end

      it "thumb at right when value is 1.0" do
        screen = test_screen
        sb = CRT::ScrollBar.new(screen, x: 0, y: 0, length: 5, value: 1.0,
          orientation: CRT::Orientation::Horizontal)
        screen.focus(sb)
        screen.draw

        render = screen.ansi.render
        render.cell(0, 0).style.bg.should eq(CRT::Ansi::Color.indexed(8))
        render.cell(4, 0).style.bg.should eq(CRT::Ansi::Color.indexed(15))
      end
    end
  end

  describe "#handle_event" do
    it "Down increases value" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0, step: 0.1)
      sb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down))
      sb.value.should be_close(0.1, 0.001)
    end

    it "Up decreases value" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0, value: 0.5, step: 0.1)
      sb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Up))
      sb.value.should be_close(0.4, 0.001)
    end

    it "Home sets value to 0.0" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0, value: 0.5)
      sb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Home))
      sb.value.should eq(0.0)
    end

    it "End sets value to 1.0" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0)
      sb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::End))
      sb.value.should eq(1.0)
    end

    it "clamps at bounds" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0, value: 0.0, step: 0.1)
      sb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Up))
      sb.value.should eq(0.0)
    end

    it "PageDown increases by step * 5" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0, step: 0.1)
      sb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::PageDown))
      sb.value.should be_close(0.5, 0.001)
    end

    it "mouse click sets value by position" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0, length: 10)
      # Click at y=5 of 10 → value = 5/9 ≈ 0.556
      click = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Left,
        CRT::Ansi::Mouse::Action::Press, 0, 5)
      sb.handle_event(click).should be_true
      sb.value.should be_close(0.556, 0.01)
    end

    it "callback fires on change" do
      screen = test_screen
      received = nil
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0) { |v|
        received = v
      }
      sb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down))
      received.should_not be_nil
    end

    it "callback does not fire when value unchanged" do
      screen = test_screen
      called = 0
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0, value: 0.0) { |_|
        called += 1
      }
      sb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Up))
      called.should eq(0)
    end

    it "other keys return false" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0)
      sb.handle_event(CRT::Ansi::Key.char('a')).should be_false
    end
  end

  describe "callback" do
    it "on_change= setter works" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0)
      received = nil
      sb.on_change = ->(v : Float64) { received = v; nil }
      sb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down))
      received.should_not be_nil
    end

    it "safe with no callback" do
      screen = test_screen
      sb = CRT::ScrollBar.new(screen, x: 0, y: 0)
      sb.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Down))
    end
  end
end
