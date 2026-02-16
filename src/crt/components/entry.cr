module CRT
  class Entry < Widget
    @line : Ansi::EditLine
    @cursor_style : Ansi::Style
    @pad : Int32
    @on_submit : (String -> Nil)?

    def self.default_theme : Theme
      CRT.theme.copy_with(
        focused: Ansi::Style.new(bg: Ansi::Color.rgb(255, 255, 255)),
        unfocused: Ansi::Style.default)
    end

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   width : Int32,
                   text : String = "",
                   style : Ansi::Style = CRT.theme.field_style,
                   @cursor_style : Ansi::Style = Ansi::Style::INVERSE,
                   border : Ansi::Border? = Ansi::Border::Single,
                   decor : Decor = Decor::None,
                   @pad : Int32 = 1,
                   theme : Theme = Entry.default_theme,
                   &on_submit : String ->)
      @on_submit = on_submit
      @line = Ansi::EditLine.new(text)
      h = 1 + (border ? 2 : 0)
      super(screen, x: x, y: y, width: width, height: h,
            style: style, border: border, decor: decor, focusable: true,
            theme: theme)
    end

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   width : Int32,
                   text : String = "",
                   style : Ansi::Style = CRT.theme.field_style,
                   @cursor_style : Ansi::Style = Ansi::Style::INVERSE,
                   border : Ansi::Border? = Ansi::Border::Single,
                   decor : Decor = Decor::None,
                   @pad : Int32 = 1,
                   theme : Theme = Entry.default_theme)
      @on_submit = nil
      @line = Ansi::EditLine.new(text)
      h = 1 + (border ? 2 : 0)
      super(screen, x: x, y: y, width: width, height: h,
            style: style, border: border, decor: decor, focusable: true,
            theme: theme)
    end

    def text : String
      @line.text
    end

    def text=(value : String) : Nil
      @line.text = value
    end

    def cursor : Int32
      @line.cursor
    end

    def cursor=(pos : Int32) : Nil
      @line.cursor = pos
    end

    property on_submit : (String -> Nil)?

    def draw(canvas : Ansi::Canvas) : Nil
      fill_style = theme.resolve(style, focused: focused?)
      p = canvas.panel(x, y, w: width, h: height)
      if b = border
        p = p.border(b, fill_style)
      end
      case decor
      when .shadow? then p = p.shadow
      when .bevel?  then p = p.bevel
      else               # none
      end
      p.fill(fill_style).draw

      cs = focused? ? fill_style.merge(@cursor_style) : nil
      @line.render(canvas, content_x + @pad, content_y,
                   content_width - @pad * 2, fill_style, cs)
    end

    def handle_event(event : Ansi::Event) : Bool
      case event
      when Ansi::Key
        handle_key(event)
      when Ansi::Mouse
        if event.button.left? && event.action.press? && hit?(event.x, event.y)
          tx = content_x + @pad
          @line.move_to_column(event.x - tx + @line.scroll)
          return true
        end
        false
      else
        false
      end
    end

    private def handle_key(key : Ansi::Key) : Bool
      case key.code
      when .char?      then @line.insert(key.char)
      when .backspace? then @line.delete_before
      when .delete?    then @line.delete_at
      when .left?      then @line.move_left
      when .right?     then @line.move_right
      when .home?      then @line.move_home
      when .end?       then @line.move_end
      when .enter?     then @on_submit.try(&.call(@line.text))
      else return false
      end
      true
    end
  end
end
