require "../spec_helper"

describe CRT::Theme do
  describe "#resolve" do
    it "returns base style with default theme" do
      theme = CRT::Theme.new
      base = CRT::Style.new(fg: CRT::Color.rgb(100, 200, 50))

      theme.resolve(base).should eq(base)
      theme.resolve(base, focused: true).should eq(base)
      theme.resolve(base, active: true).should eq(base)
      theme.resolve(base, focused: true, active: true).should eq(base)
    end

    it "merges focused delta when focused" do
      theme = CRT::Theme.new(focused: CRT::Style.new(bold: true))
      base = CRT::Style.new(fg: CRT::Color.rgb(100, 200, 50))

      result = theme.resolve(base, focused: true)
      result.bold.should be_true
      result.fg.should eq(base.fg)
    end

    it "merges unfocused delta when not focused" do
      theme = CRT::Theme.new(unfocused: CRT::Style.new(dim: true))
      base = CRT::Style.default

      result = theme.resolve(base)
      result.dim.should be_true
    end

    it "merges active delta when active" do
      theme = CRT::Theme.new(active: CRT::Style.new(fg: CRT::Color.rgb(255, 0, 0)))
      base = CRT::Style.default

      result = theme.resolve(base, active: true)
      result.fg.should eq(CRT::Color.rgb(255, 0, 0))
    end

    it "merges passive delta when not active" do
      theme = CRT::Theme.new(passive: CRT::Style.new(dim: true))
      base = CRT::Style.default

      result = theme.resolve(base)
      result.dim.should be_true
    end

    it "composes both axes" do
      theme = CRT::Theme.new(
        focused: CRT::Style.new(bold: true),
        active: CRT::Style.new(italic: true))
      base = CRT::Style.default

      result = theme.resolve(base, focused: true, active: true)
      result.bold.should be_true
      result.italic.should be_true
    end

    it "focus merges last — focus color overrides active color" do
      theme = CRT::Theme.new(
        focused: CRT::Style.new(fg: CRT::Color.rgb(0, 255, 0)),
        active: CRT::Style.new(fg: CRT::Color.rgb(255, 0, 0)))
      base = CRT::Style.default

      result = theme.resolve(base, focused: true, active: true)
      result.fg.should eq(CRT::Color.rgb(0, 255, 0))
    end

    it "merges ghosted on top of everything" do
      theme = CRT::Theme.new(
        focused: CRT::Style.new(fg: CRT::Color.rgb(0, 255, 0)),
        ghosted: CRT::Style.new(dim: true, fg: CRT::Color.rgb(80, 80, 80)))
      base = CRT::Style.default

      result = theme.resolve(base, focused: true, ghosted: true)
      result.dim.should be_true
      result.fg.should eq(CRT::Color.rgb(80, 80, 80))
    end

    it "does not apply ghosted when not ghosted" do
      theme = CRT::Theme.new(
        ghosted: CRT::Style.new(dim: true))
      base = CRT::Style.default

      result = theme.resolve(base)
      result.dim.should be_false
    end
  end

  describe "#base" do
    it "merges base onto style before state deltas" do
      theme = CRT::Theme.new(
        base: CRT::Style.new(fg: CRT::Color.rgb(180, 180, 200),
                              bg: CRT::Color.rgb(40, 40, 50)))

      result = theme.resolve(CRT::Style.default)
      result.fg.should eq(CRT::Color.rgb(180, 180, 200))
      result.bg.should eq(CRT::Color.rgb(40, 40, 50))
    end

    it "widget style overrides base" do
      theme = CRT::Theme.new(
        base: CRT::Style.new(fg: CRT::Color.rgb(180, 180, 200)))
      widget_style = CRT::Style.new(fg: CRT::Color.rgb(255, 0, 0))

      result = theme.resolve(widget_style)
      result.fg.should eq(CRT::Color.rgb(255, 0, 0))
    end

    it "state deltas override base" do
      theme = CRT::Theme.new(
        base: CRT::Style.new(fg: CRT::Color.rgb(180, 180, 200)),
        focused: CRT::Style.new(fg: CRT::Color.rgb(0, 255, 0)))

      result = theme.resolve(CRT::Style.default, focused: true)
      result.fg.should eq(CRT::Color.rgb(0, 255, 0))
    end

    it "base provides bg, state delta provides attribute" do
      theme = CRT::Theme.new(
        base: CRT::Style.new(bg: CRT::Color.rgb(40, 40, 50)),
        focused: CRT::Style.new(bold: true))

      result = theme.resolve(CRT::Style.default, focused: true)
      result.bg.should eq(CRT::Color.rgb(40, 40, 50))
      result.bold.should be_true
    end
  end

  describe "CRT.theme" do
    it "returns the global theme" do
      theme = CRT.theme
      theme.should be_a(CRT::Theme)
      theme.base.fg.should eq(CRT::Color.rgb(180, 180, 200))
      theme.base.bg.should eq(CRT::Color.rgb(40, 40, 50))
    end

    it "can be replaced" do
      original = CRT.theme
      custom = CRT::Theme.new(base: CRT::Style.new(bold: true))
      CRT.theme = custom
      CRT.theme.should eq(custom)
      CRT.theme = original
    end
  end

  describe "#copy_with" do
    it "creates a modified theme" do
      theme = CRT::Theme.new(focused: CRT::Style::INVERSE)
      modified = theme.copy_with(active: CRT::Style::BOLD)

      modified.focused.should eq(CRT::Style::INVERSE)
      modified.active.should eq(CRT::Style::BOLD)
    end
  end
end
