module CRT
  # Two-color palette theme. All UI shades are derived from `bg` and `fg`
  # via linear interpolation, producing a direction-agnostic color ramp:
  #
  #   bg ── bevel ── dim ── mid ── fg ── bright
  #   0.0   0.15    0.25   0.5    1.0   beyond
  #
  # "Beyond" means `bright` extends past `fg` toward the opposite extreme
  # (white when bg is dark, black when bg is bright). This makes the ramp
  # work identically for dark-on-light and light-on-dark color schemes.
  #
  # Widgets pick named palette colors directly instead of composing
  # boolean axes. Three convenience styles cover the common cases:
  #
  #   base        — fg text on bg background (normal widget chrome)
  #   field       — bg text on fg background (interactive fields)
  #   field_focus — bg text on bright background (focused fields)
  #
  record Theme, bg : Ansi::Color, fg : Ansi::Color do
    # Subtle edge decoration (bevel lines, separators).
    def bevel : Ansi::Color
      Ansi::Color.lerp(bg, fg, 0.15)
    end

    # De-emphasized elements (dim underlines, inactive chrome).
    def dim : Ansi::Color
      Ansi::Color.lerp(bg, fg, 0.25)
    end

    # Medium prominence (unselected dialog buttons, mid-tone fills).
    def mid : Ansi::Color
      Ansi::Color.lerp(bg, fg, 0.5)
    end

    # High-emphasis focus indicator. Extends past fg toward the
    # opposite luminance extreme — white for dark themes, black for
    # light themes.
    def bright : Ansi::Color
      extreme = luminance(bg) < 128 ? Ansi::Color.rgb(255, 255, 255)
                                    : Ansi::Color.rgb(0, 0, 0)
      Ansi::Color.lerp(fg, extreme, 0.5)
    end

    # Normal widget background with fg text.
    def base : Ansi::Style
      Ansi::Style.new(fg: fg, bg: bg)
    end

    # Interactive field — swapped colors (bg text on fg background).
    def field : Ansi::Style
      Ansi::Style.new(fg: bg, bg: fg)
    end

    # Focused interactive field — bg text on bright background.
    def field_focus : Ansi::Style
      Ansi::Style.new(fg: bg, bg: bright)
    end

    # Average luminance of a color (0–255). Used to determine whether
    # the theme is dark or light for computing `bright`.
    private def luminance(c : Ansi::Color) : Int32
      return 0 if c.default?
      (c.red + c.green + c.blue) // 3
    end
  end

  @@theme = Theme.new(
    bg: Ansi::Color.rgb(40, 40, 50),
    fg: Ansi::Color.rgb(180, 180, 200))

  def self.theme : Theme
    @@theme
  end

  def self.theme=(@@theme : Theme) : Theme
  end
end
