module CRT
  record Theme,
    focused : Ansi::Style = Ansi::Style.default,
    unfocused : Ansi::Style = Ansi::Style.default,
    active : Ansi::Style = Ansi::Style.default,
    passive : Ansi::Style = Ansi::Style.default,
    ghosted : Ansi::Style = Ansi::Style.default do

    def resolve(base : Ansi::Style, *,
                focused : Bool = false,
                active : Bool = false,
                ghosted : Bool = false) : Ansi::Style
      s = active ? base.merge(@active) : base.merge(@passive)
      s = focused ? s.merge(@focused) : s.merge(@unfocused)
      s = s.merge(@ghosted) if ghosted
      s
    end
  end
end
