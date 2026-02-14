require "../../spec_helper"

describe CRT::Label do
  describe "auto-sizing" do
    it "sizes from single-line text" do
      screen = test_screen
      label = CRT::Label.new(screen, x: 0, y: 0, text: "Hello")
      label.width.should eq(5)
      label.height.should eq(1)
    end

    it "sizes from multi-line text" do
      screen = test_screen
      label = CRT::Label.new(screen, x: 0, y: 0, text: "Hello\nWorld!")
      label.width.should eq(6)   # "World!" is widest
      label.height.should eq(2)
    end

    it "accounts for border in auto-sizing" do
      screen = test_screen
      label = CRT::Label.new(screen, x: 0, y: 0, text: "Hi",
        border: CRT::Ansi::Border::Single)
      label.width.should eq(4)   # 2 + border(2)
      label.height.should eq(3)  # 1 + border(2)
    end

    it "accounts for padding in auto-sizing" do
      screen = test_screen
      label = CRT::Label.new(screen, x: 0, y: 0, text: "Hi", pad: 1)
      label.width.should eq(4)   # 2 + pad(2)
      label.height.should eq(1)
    end
  end

  describe "explicit sizing" do
    it "uses provided width and height" do
      screen = test_screen
      label = CRT::Label.new(screen, x: 0, y: 0, width: 20, height: 5, text: "Hi")
      label.width.should eq(20)
      label.height.should eq(5)
    end

    it "uses provided width with auto height" do
      screen = test_screen
      label = CRT::Label.new(screen, x: 0, y: 0, width: 20, text: "Line1\nLine2")
      label.width.should eq(20)
      label.height.should eq(2)
    end
  end

  describe "#text=" do
    it "updates text for next draw" do
      screen = test_screen
      label = CRT::Label.new(screen, x: 0, y: 0, width: 10, height: 1, text: "Before")
      label.text = "After"
      label.text.should eq("After")
    end
  end

  describe "#draw" do
    it "renders text to canvas" do
      screen = test_screen
      label = CRT::Label.new(screen, x: 0, y: 0, width: 10, height: 1, text: "Hello")
      screen.draw

      render = screen.ansi.render
      render.cell(0, 0).grapheme.should eq("H")
      render.cell(1, 0).grapheme.should eq("e")
      render.cell(2, 0).grapheme.should eq("l")
      render.cell(3, 0).grapheme.should eq("l")
      render.cell(4, 0).grapheme.should eq("o")
    end

    it "renders text inside border" do
      screen = test_screen
      label = CRT::Label.new(screen, x: 0, y: 0, width: 7, height: 3,
        text: "Hi", border: CRT::Ansi::Border::Single)
      screen.draw

      render = screen.ansi.render
      # Border top-left corner
      render.cell(0, 0).grapheme.should eq("\u250C")
      # Text inside border
      render.cell(1, 1).grapheme.should eq("H")
      render.cell(2, 1).grapheme.should eq("i")
    end

    it "renders Style::Text" do
      screen = test_screen
      styled = CRT::Ansi::Style::Text.new.add("Bold", CRT::Ansi::Style::BOLD)
      label = CRT::Label.new(screen, x: 0, y: 0, width: 10, height: 1, text: styled)
      screen.draw

      render = screen.ansi.render
      render.cell(0, 0).grapheme.should eq("B")
      render.cell(0, 0).style.bold.should be_true
    end

    it "applies fill style" do
      screen = test_screen
      fill = CRT::Ansi::Style.new(bg: CRT::Ansi::Color.indexed(1))
      label = CRT::Label.new(screen, x: 0, y: 0, width: 5, height: 1,
        text: "", fill: fill)
      screen.draw

      render = screen.ansi.render
      render.cell(0, 0).style.bg.should eq(CRT::Ansi::Color.indexed(1))
    end
  end

  describe "not focusable" do
    it "is not focusable" do
      screen = test_screen
      label = CRT::Label.new(screen, x: 0, y: 0, text: "Hi")
      label.focusable?.should be_false
    end
  end
end
