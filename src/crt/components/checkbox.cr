module CRT
  class Checkbox < Widget
    @text : String
    @checked : Bool
    @checked_mark : String
    @unchecked_mark : String
    @focus_style : Ansi::Style
    @pad : Int32
    @on_change : (Bool -> Nil)?

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   @text : String,
                   @checked : Bool = false,
                   width : Int32? = nil, height : Int32? = nil,
                   style : Ansi::Style = Ansi::Style.default,
                   @focus_style : Ansi::Style = Ansi::Style::INVERSE,
                   @checked_mark : String = "[x]",
                   @unchecked_mark : String = "[ ]",
                   border : Ansi::Border? = nil,
                   shadow : Bool = false,
                   @pad : Int32 = 0,
                   &on_change : Bool ->)
      @on_change = on_change
      w, h = compute_size(border)
      super(screen, x: x, y: y, width: width || w, height: height || h,
            style: style, border: border, shadow: shadow, focusable: true)
    end

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   @text : String,
                   @checked : Bool = false,
                   width : Int32? = nil, height : Int32? = nil,
                   style : Ansi::Style = Ansi::Style.default,
                   @focus_style : Ansi::Style = Ansi::Style::INVERSE,
                   @checked_mark : String = "[x]",
                   @unchecked_mark : String = "[ ]",
                   border : Ansi::Border? = nil,
                   shadow : Bool = false,
                   @pad : Int32 = 0)
      @on_change = nil
      w, h = compute_size(border)
      super(screen, x: x, y: y, width: width || w, height: height || h,
            style: style, border: border, shadow: shadow, focusable: true)
    end

    def text : String
      @text
    end

    def text=(@text : String) : Nil
    end

    getter? checked : Bool

    def checked=(@checked : Bool) : Nil
    end

    property on_change : (Bool -> Nil)?

    def toggle : Nil
      @checked = !@checked
      @on_change.try(&.call(@checked))
    end

    def check : Nil
      return if @checked
      @checked = true
      @on_change.try(&.call(true))
    end

    def uncheck : Nil
      return unless @checked
      @checked = false
      @on_change.try(&.call(false))
    end

    def draw(canvas : Ansi::Canvas) : Nil
      active = focused? ? style.merge(@focus_style) : style
      mark = checked? ? @checked_mark : @unchecked_mark
      display = "#{mark} #{@text}"
      p = canvas.panel(x, y, w: width, h: height)
      if b = border
        p = p.border(b, active)
      end
      p = p.shadow if shadow
      p.fill(active)
       .text(display, style: active, align: Ansi::Align::Left, valign: Ansi::VAlign::Middle, pad: @pad)
       .draw
    end

    def handle_event(event : Ansi::Event) : Bool
      case event
      when Ansi::Key
        if event.code.enter? || (event.code.char? && event.char == " ")
          toggle
          return true
        end
      when Ansi::Mouse
        if event.button.left? && event.action.press? && hit?(event.x, event.y)
          toggle
          return true
        end
      end
      false
    end

    private def compute_size(border : Ansi::Border?) : {Int32, Int32}
      display = "#{@checked_mark} #{@text}"
      inset = border ? 2 : 0
      w = Ansi::DisplayWidth.width(display) + @pad * 2 + inset
      h = 1 + inset
      {w, h}
    end
  end
end
