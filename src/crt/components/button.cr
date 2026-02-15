module CRT
  class Button < Widget
    UNFOCUSED_DEFAULT = Ansi::Style.new(dim: true, inverse: true)

    @text : String
    @focus_style : Ansi::Style
    @unfocus_style : Ansi::Style
    @pad : Int32
    @action : (-> Nil)?

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   @text : String,
                   width : Int32? = nil, height : Int32? = nil,
                   style : Ansi::Style = Ansi::Style.default,
                   @focus_style : Ansi::Style = Ansi::Style::INVERSE,
                   @unfocus_style : Ansi::Style = UNFOCUSED_DEFAULT,
                   border : Ansi::Border? = nil,
                   shadow : Bool = false,
                   @pad : Int32 = 2,
                   &action : -> Nil)
      @action = action
      w, h = compute_size(@text, border, @pad)
      super(screen, x: x, y: y, width: width || w, height: height || h,
            style: style, border: border, shadow: shadow, focusable: true)
    end

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   @text : String,
                   width : Int32? = nil, height : Int32? = nil,
                   style : Ansi::Style = Ansi::Style.default,
                   @focus_style : Ansi::Style = Ansi::Style::INVERSE,
                   @unfocus_style : Ansi::Style = UNFOCUSED_DEFAULT,
                   border : Ansi::Border? = nil,
                   shadow : Bool = false,
                   @pad : Int32 = 2)
      @action = nil
      w, h = compute_size(@text, border, @pad)
      super(screen, x: x, y: y, width: width || w, height: height || h,
            style: style, border: border, shadow: shadow, focusable: true)
    end

    def text : String
      @text
    end

    def text=(@text : String) : Nil
    end

    property action : (-> Nil)?

    def draw(canvas : Ansi::Canvas) : Nil
      active = focused? ? style.merge(@focus_style) : style.merge(@unfocus_style)
      p = canvas.panel(x, y, w: width, h: height)
      if b = border
        p = p.border(b, active)
      end
      p = p.shadow if shadow
      p.fill(active)
       .text(@text, style: active, align: Ansi::Align::Center, valign: Ansi::VAlign::Middle, pad: @pad)
       .draw
    end

    def handle_event(event : Ansi::Event) : Bool
      case event
      when Ansi::Key
        if event.code.enter? || (event.code.char? && event.char == " ")
          activate
          return true
        end
      when Ansi::Mouse
        if event.button.left? && event.action.press? && hit?(event.x, event.y)
          activate
          return true
        end
      end
      false
    end

    def activate : Nil
      @action.try(&.call)
    end

    private def compute_size(text : String, border : Ansi::Border?,
                             pad : Int32) : {Int32, Int32}
      inset = border ? 2 : 0
      w = Ansi::DisplayWidth.width(text) + pad * 2 + inset
      h = 1 + inset
      {w, h}
    end
  end
end
