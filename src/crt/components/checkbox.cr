module CRT
  class Checkbox < Widget
    @text : String
    @checked : Bool
    @checked_mark : String
    @unchecked_mark : String
    @pad : Int32
    @on_change : (Bool -> Nil)?

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   @text : String,
                   @checked : Bool = false,
                   width : Int32? = nil, height : Int32? = nil,
                   style : Ansi::Style = CRT.theme.base,
                   @checked_mark : String = "⬛",
                   @unchecked_mark : String = "⬜",
                   border : Ansi::Border? = nil,
                   decor : Decor = Decor::None,
                   @pad : Int32 = 0,
                   &on_change : Bool ->)
      @on_change = on_change
      w, h = compute_size(border)
      super(screen, x: x, y: y, width: width || w, height: height || h,
            style: style, border: border, decor: decor, focusable: true)
    end

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   @text : String,
                   @checked : Bool = false,
                   width : Int32? = nil, height : Int32? = nil,
                   style : Ansi::Style = CRT.theme.base,
                   @checked_mark : String = "⬛",
                   @unchecked_mark : String = "⬜",
                   border : Ansi::Border? = nil,
                   decor : Decor = Decor::None,
                   @pad : Int32 = 0)
      @on_change = nil
      w, h = compute_size(border)
      super(screen, x: x, y: y, width: width || w, height: height || h,
            style: style, border: border, decor: decor, focusable: true)
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
      resolved = focused? ? theme.field : style
      p = canvas.panel(x, y, w: width, h: height)
      if b = border
        p = p.border(b, style)
      end
      case decor
      when .shadow? then p = p.shadow
      when .bevel?  then p = p.bevel
      else               # none
      end
      p.fill(style).draw

      mark = checked? ? @checked_mark : @unchecked_mark
      mark_w = {Ansi::DisplayWidth.width(@checked_mark),
                Ansi::DisplayWidth.width(@unchecked_mark)}.max
      canvas.write(content_x + @pad, content_y, mark, style)
      canvas.write(content_x + @pad + mark_w + 1, content_y, @text, resolved)
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
      mark_w = {Ansi::DisplayWidth.width(@checked_mark),
                Ansi::DisplayWidth.width(@unchecked_mark)}.max
      inset = border ? 2 : 0
      w = mark_w + 1 + Ansi::DisplayWidth.width(@text) + @pad * 2 + inset
      h = 1 + inset
      {w, h}
    end
  end
end
