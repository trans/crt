require "../../spec_helper"

describe CRT::ProgressBar do
  describe "construction" do
    it "is not focusable" do
      screen = test_screen
      bar = CRT::ProgressBar.new(screen, x: 0, y: 0, width: 20)
      bar.focusable?.should be_false
    end

    it "height is 1 without border" do
      screen = test_screen
      bar = CRT::ProgressBar.new(screen, x: 0, y: 0, width: 20)
      bar.height.should eq(1)
    end

    it "height is 3 with border" do
      screen = test_screen
      bar = CRT::ProgressBar.new(screen, x: 0, y: 0, width: 20,
        border: CRT::Ansi::Border::Single)
      bar.height.should eq(3)
    end

    it "value defaults to 0.0" do
      screen = test_screen
      bar = CRT::ProgressBar.new(screen, x: 0, y: 0, width: 20)
      bar.value.should eq(0.0)
    end

    it "clamps initial value" do
      screen = test_screen
      bar = CRT::ProgressBar.new(screen, x: 0, y: 0, width: 20, value: 2.0)
      bar.value.should eq(1.0)
    end
  end

  describe "#value=" do
    it "updates value" do
      screen = test_screen
      bar = CRT::ProgressBar.new(screen, x: 0, y: 0, width: 20)
      bar.value = 0.5
      bar.value.should eq(0.5)
    end

    it "clamps above 1.0" do
      screen = test_screen
      bar = CRT::ProgressBar.new(screen, x: 0, y: 0, width: 20)
      bar.value = 5.0
      bar.value.should eq(1.0)
    end

    it "clamps below 0.0" do
      screen = test_screen
      bar = CRT::ProgressBar.new(screen, x: 0, y: 0, width: 20)
      bar.value = -1.0
      bar.value.should eq(0.0)
    end
  end

  describe "#draw" do
    it "renders all empty at 0.0" do
      screen = test_screen
      bar = CRT::ProgressBar.new(screen, x: 0, y: 0, width: 10)
      screen.draw

      render = screen.ansi.render
      (0...10).each { |i| render.cell(i, 0).grapheme.should eq("░") }
    end

    it "renders all filled at 1.0" do
      screen = test_screen
      bar = CRT::ProgressBar.new(screen, x: 0, y: 0, width: 10, value: 1.0)
      screen.draw

      render = screen.ansi.render
      (0...10).each { |i| render.cell(i, 0).grapheme.should eq("█") }
    end

    it "renders half filled at 0.5" do
      screen = test_screen
      bar = CRT::ProgressBar.new(screen, x: 0, y: 0, width: 10, value: 0.5)
      screen.draw

      render = screen.ansi.render
      (0...5).each { |i| render.cell(i, 0).grapheme.should eq("█") }
      (5...10).each { |i| render.cell(i, 0).grapheme.should eq("░") }
    end

    it "renders inside border" do
      screen = test_screen
      bar = CRT::ProgressBar.new(screen, x: 0, y: 0, width: 12, value: 1.0,
        border: CRT::Ansi::Border::Single)
      screen.draw

      render = screen.ansi.render
      render.cell(0, 0).grapheme.should eq("\u250C")  # border
      (1..10).each { |i| render.cell(i, 1).grapheme.should eq("█") }
    end

    it "uses custom fill_style" do
      screen = test_screen
      fs = CRT::Ansi::Style.new(fg: CRT::Ansi::Color.indexed(2))
      bar = CRT::ProgressBar.new(screen, x: 0, y: 0, width: 10, value: 1.0,
        fill_style: fs)
      screen.draw

      render = screen.ansi.render
      render.cell(0, 0).style.fg.should eq(CRT::Ansi::Color.indexed(2))
    end

    it "uses custom empty_style" do
      screen = test_screen
      es = CRT::Ansi::Style.new(fg: CRT::Ansi::Color.indexed(8))
      bar = CRT::ProgressBar.new(screen, x: 0, y: 0, width: 10, value: 0.0,
        empty_style: es)
      screen.draw

      render = screen.ansi.render
      render.cell(0, 0).style.fg.should eq(CRT::Ansi::Color.indexed(8))
    end
  end
end
