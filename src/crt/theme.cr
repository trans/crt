module CRT
  record Theme,
    base : Ansi::Style = Ansi::Style.default,
    focused : Ansi::Style = Ansi::Style.default,
    unfocused : Ansi::Style = Ansi::Style.default,
    active : Ansi::Style = Ansi::Style.default,
    passive : Ansi::Style = Ansi::Style.default,
    ghosted : Ansi::Style = Ansi::Style.default do

    def field_style : Ansi::Style
      Ansi::Style.new(fg: @base.bg, bg: @base.fg)
    end

    def resolve(style : Ansi::Style, *,
                focused : Bool = false,
                active : Bool = false,
                ghosted : Bool = false) : Ansi::Style
      s = @base.merge(style)
      s = active ? s.merge(@active) : s.merge(@passive)
      s = focused ? s.merge(@focused) : s.merge(@unfocused)
      s = s.merge(@ghosted) if ghosted
      s
    end
  end

  @@theme = Theme.new(
    base: Ansi::Style.new(
      fg: Ansi::Color.rgb(180, 180, 200),
      bg: Ansi::Color.rgb(40, 40, 50)),
    focused: Ansi::Style::INVERSE,
    unfocused: Ansi::Style.new(dim: true, inverse: true))

  def self.theme : Theme
    @@theme
  end

  def self.theme=(@@theme : Theme) : Theme
  end
end
