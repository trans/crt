require "../spec_helper"

describe CRT::Theme do
  theme = CRT::Theme.new(
    bg: CRT::Color.rgb(40, 40, 50),
    fg: CRT::Color.rgb(180, 180, 200))

  describe "#bevel" do
    it "returns a color between bg and fg at 15%" do
      c = theme.bevel
      c.red.should be > 40
      c.red.should be < 180
    end
  end

  describe "#dim" do
    it "returns a color at 25% from bg toward fg" do
      c = theme.dim
      # lerp(40, 180, 0.25) = 75
      c.red.should eq(75)
      c.green.should eq(75)
      c.blue.should eq(88) # lerp(50, 200, 0.25) = 87.5 → 88
    end
  end

  describe "#mid" do
    it "returns a color at 50% from bg toward fg" do
      c = theme.mid
      # lerp(40, 180, 0.5) = 110
      c.red.should eq(110)
      c.green.should eq(110)
      c.blue.should eq(125)
    end
  end

  describe "#bright" do
    it "extends past fg toward white for dark bg" do
      c = theme.bright
      # Dark theme: extreme = white(255,255,255)
      # lerp(180, 255, 0.5) = 218 (rounded)
      c.red.should eq(218)
      c.green.should eq(218)
      c.blue.should eq(228) # lerp(200, 255, 0.5) = 227.5 → 228
    end

    it "extends past fg toward black for light bg" do
      light = CRT::Theme.new(
        bg: CRT::Color.rgb(220, 220, 230),
        fg: CRT::Color.rgb(40, 40, 50))
      c = light.bright
      # Light theme: extreme = black(0,0,0)
      # lerp(40, 0, 0.5) = 20
      c.red.should eq(20)
      c.green.should eq(20)
      c.blue.should eq(25)
    end
  end

  describe "#base" do
    it "returns fg text on bg background" do
      s = theme.base
      s.fg.should eq(theme.fg)
      s.bg.should eq(theme.bg)
    end
  end

  describe "#field" do
    it "returns swapped colors (bg text on fg background)" do
      s = theme.field
      s.fg.should eq(theme.bg)
      s.bg.should eq(theme.fg)
    end
  end

  describe "#field_focus" do
    it "returns bg text on bright background" do
      s = theme.field_focus
      s.fg.should eq(theme.bg)
      s.bg.should eq(theme.bright)
    end
  end

  describe "CRT.theme" do
    it "returns the global theme" do
      t = CRT.theme
      t.should be_a(CRT::Theme)
      t.bg.should eq(CRT::Color.rgb(40, 40, 50))
      t.fg.should eq(CRT::Color.rgb(180, 180, 200))
    end

    it "can be replaced" do
      original = CRT.theme
      custom = CRT::Theme.new(
        bg: CRT::Color.rgb(0, 0, 0),
        fg: CRT::Color.rgb(255, 255, 255))
      CRT.theme = custom
      CRT.theme.should eq(custom)
      CRT.theme = original
    end
  end

  describe "#copy_with" do
    it "creates a modified theme" do
      modified = theme.copy_with(bg: CRT::Color.rgb(0, 0, 0))
      modified.bg.should eq(CRT::Color.rgb(0, 0, 0))
      modified.fg.should eq(theme.fg)
    end
  end
end
