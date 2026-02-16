require "../../spec_helper"

describe CRT::Dialog do
  describe "construction" do
    it "auto-sizes from message and buttons" do
      screen = test_screen
      d = CRT::Dialog.new(screen, message: "Hello")
      d.width.should be > 0
      d.height.should be > 0
    end

    it "centers on screen" do
      screen = test_screen
      d = CRT::Dialog.new(screen, message: "Test")
      # test_screen is 80x24
      d.x.should eq(screen.center_x(d.width + 1)) # +1 for decor
      d.y.should eq(screen.center_y(d.height + 1))
    end

    it "sets screen modal" do
      screen = test_screen
      d = CRT::Dialog.new(screen, message: "Test")
      screen.modal.should eq(d)
    end

    it "defaults to single OK button" do
      screen = test_screen
      d = CRT::Dialog.new(screen, message: "Test")
      d.buttons.should eq(["OK"])
    end

    it "is focusable" do
      screen = test_screen
      d = CRT::Dialog.new(screen, message: "Test")
      d.focusable?.should be_true
    end

    it "raises to top of widget list" do
      screen = test_screen
      CRT::Label.new(screen, x: 0, y: 0, text: "bg")
      d = CRT::Dialog.new(screen, message: "Test")
      screen.widgets.last.should eq(d)
    end

    it "gets focus" do
      screen = test_screen
      CRT::Label.new(screen, x: 0, y: 0, text: "bg")
      d = CRT::Dialog.new(screen, message: "Test")
      screen.focused_widget.should eq(d)
    end
  end

  describe "modal behavior" do
    it "dispatch routes to dialog when modal" do
      screen = test_screen
      received = false
      d = CRT::Dialog.new(screen, message: "Test") { |_| received = true }
      screen.dispatch(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Enter))
      received.should be_true
    end

    it "Tab does not cycle away from dialog" do
      screen = test_screen
      btn = CRT::Button.new(screen, x: 0, y: 0, text: "bg")
      d = CRT::Dialog.new(screen, message: "Test", buttons: ["A", "B"])
      screen.dispatch(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab))
      # Dialog still has modal, button selection changed
      d.selected.should eq(1)
      screen.modal.should eq(d)
    end

    it "unregister clears modal" do
      screen = test_screen
      d = CRT::Dialog.new(screen, message: "Test")
      screen.unregister(d)
      screen.modal.should be_nil
    end
  end

  describe "button interaction" do
    it "Tab cycles selected forward" do
      screen = test_screen
      d = CRT::Dialog.new(screen, message: "Test", buttons: ["A", "B", "C"])
      d.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab))
      d.selected.should eq(1)
      d.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab))
      d.selected.should eq(2)
    end

    it "Tab wraps around" do
      screen = test_screen
      d = CRT::Dialog.new(screen, message: "Test", buttons: ["A", "B"])
      d.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab))
      d.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Tab))
      d.selected.should eq(0)
    end

    it "Right cycles selected forward" do
      screen = test_screen
      d = CRT::Dialog.new(screen, message: "Test", buttons: ["A", "B"])
      d.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Right))
      d.selected.should eq(1)
    end

    it "Left cycles selected backward" do
      screen = test_screen
      d = CRT::Dialog.new(screen, message: "Test", buttons: ["A", "B"])
      d.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Right))
      d.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Left))
      d.selected.should eq(0)
    end

    it "Left wraps around" do
      screen = test_screen
      d = CRT::Dialog.new(screen, message: "Test", buttons: ["A", "B"])
      d.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Left))
      d.selected.should eq(1)
    end

    it "Enter fires callback with selected index" do
      screen = test_screen
      choice = -1
      d = CRT::Dialog.new(screen, message: "Test", buttons: ["Cancel", "OK"]) { |c|
        choice = c
      }
      d.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Right))
      d.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Enter))
      choice.should eq(1)
    end

    it "Space fires callback with selected index" do
      screen = test_screen
      choice = -1
      d = CRT::Dialog.new(screen, message: "Test") { |c| choice = c }
      d.handle_event(CRT::Ansi::Key.char(' '))
      choice.should eq(0)
    end

    it "Escape fires callback with 0" do
      screen = test_screen
      choice = -1
      d = CRT::Dialog.new(screen, message: "Test", buttons: ["Cancel", "Delete"]) { |c|
        choice = c
      }
      d.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Right))
      d.selected.should eq(1)
      d.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Escape))
      choice.should eq(0)
    end
  end

  describe "dismiss" do
    it "clears screen modal" do
      screen = test_screen
      d = CRT::Dialog.new(screen, message: "Test") { |_| }
      d.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Enter))
      screen.modal.should be_nil
    end

    it "removes from screen widgets" do
      screen = test_screen
      d = CRT::Dialog.new(screen, message: "Test") { |_| }
      screen.widgets.should contain(d)
      d.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Enter))
      screen.widgets.should_not contain(d)
    end
  end

  describe "#draw" do
    it "renders border" do
      screen = test_screen
      d = CRT::Dialog.new(screen, message: "Hello")
      screen.draw

      render = screen.ansi.render
      # Top-left corner of dialog should have border character
      cell = render.cell(d.x, d.y)
      cell.grapheme.should_not eq(" ")
    end

    it "renders title" do
      screen = test_screen
      d = CRT::Dialog.new(screen, title: "Info", message: "Hello")
      screen.draw

      # Title should appear on top border row
      render = screen.ansi.render
      found = false
      (d.x..d.x + d.width - 1).each do |cx|
        if render.cell(cx, d.y).grapheme == "I"
          found = true
          break
        end
      end
      found.should be_true
    end

    it "renders message" do
      screen = test_screen
      d = CRT::Dialog.new(screen, message: "XYZ")
      screen.draw

      render = screen.ansi.render
      found = false
      (d.content_x..d.content_x + d.content_width - 1).each do |cx|
        (d.content_y..d.content_y + d.content_height - 1).each do |cy|
          if render.cell(cx, cy).grapheme == "X"
            found = true
            break
          end
        end
        break if found
      end
      found.should be_true
    end

    it "renders buttons" do
      screen = test_screen
      d = CRT::Dialog.new(screen, message: "Test", buttons: ["OK"])
      screen.draw

      render = screen.ansi.render
      found = false
      (d.content_x..d.content_x + d.content_width - 1).each do |cx|
        (d.content_y..d.content_y + d.content_height - 1).each do |cy|
          if render.cell(cx, cy).grapheme == "O"
            next_cell = render.cell(cx + 1, cy)
            if next_cell.grapheme == "K"
              found = true
              break
            end
          end
        end
        break if found
      end
      found.should be_true
    end

    it "selected button has field style" do
      screen = test_screen
      d = CRT::Dialog.new(screen, message: "Test", buttons: ["A", "B"])
      d.handle_event(CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Right))
      screen.draw

      render = screen.ansi.render
      # Find "B" button — it should have field style (swapped colors)
      (d.content_x..d.content_x + d.content_width - 1).each do |cx|
        (d.content_y..d.content_y + d.content_height - 1).each do |cy|
          if render.cell(cx, cy).grapheme == "B"
            render.cell(cx, cy).style.bg.should eq(CRT.theme.fg)
          end
        end
      end
    end
  end
end
