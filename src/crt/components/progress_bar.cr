module CRT
  class ProgressBar < Widget
    @value : Float64
    @fill_char : String
    @empty_char : String
    @fill_style : Ansi::Style?
    @empty_style : Ansi::Style?

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   width : Int32,
                   @value : Float64 = 0.0,
                   style : Ansi::Style = Ansi::Style.default,
                   @fill_char : String = "█",
                   @empty_char : String = "░",
                   @fill_style : Ansi::Style? = nil,
                   @empty_style : Ansi::Style? = nil,
                   border : Ansi::Border? = nil,
                   shadow : Bool = false)
      @value = @value.clamp(0.0, 1.0)
      h = 1 + (border ? 2 : 0)
      super(screen, x: x, y: y, width: width, height: h,
            style: style, border: border, shadow: shadow, focusable: false)
    end

    getter value : Float64

    def value=(v : Float64) : Nil
      @value = v.clamp(0.0, 1.0)
    end

    getter fill_char : String
    getter empty_char : String
    getter fill_style : Ansi::Style?
    getter empty_style : Ansi::Style?

    def draw(canvas : Ansi::Canvas) : Nil
      panel(canvas).fill(style).draw

      tw = content_width
      filled = (tw * @value).round.to_i.clamp(0, tw)
      fs = @fill_style || style
      es = @empty_style || style

      filled.times { |i| canvas.put(content_x + i, content_y, @fill_char, fs) }
      (tw - filled).times { |i| canvas.put(content_x + filled + i, content_y, @empty_char, es) }
    end
  end
end
