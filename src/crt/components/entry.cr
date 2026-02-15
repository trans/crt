module CRT
  class Entry < Widget
    @text : String
    @cursor : Int32
    @scroll : Int32
    @cursor_style : Ansi::Style
    @pad : Int32
    @on_submit : (String -> Nil)?

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   width : Int32,
                   @text : String = "",
                   style : Ansi::Style = Ansi::Style.default,
                   @cursor_style : Ansi::Style = Ansi::Style::INVERSE,
                   border : Ansi::Border? = Ansi::Border::Single,
                   shadow : Bool = false,
                   @pad : Int32 = 1,
                   &on_submit : String ->)
      @on_submit = on_submit
      @cursor = 0
      @scroll = 0
      h = 1 + (border ? 2 : 0)
      super(screen, x: x, y: y, width: width, height: h,
            style: style, border: border, shadow: shadow, focusable: true)
    end

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   width : Int32,
                   @text : String = "",
                   style : Ansi::Style = Ansi::Style.default,
                   @cursor_style : Ansi::Style = Ansi::Style::INVERSE,
                   border : Ansi::Border? = Ansi::Border::Single,
                   shadow : Bool = false,
                   @pad : Int32 = 1)
      @on_submit = nil
      @cursor = 0
      @scroll = 0
      h = 1 + (border ? 2 : 0)
      super(screen, x: x, y: y, width: width, height: h,
            style: style, border: border, shadow: shadow, focusable: true)
    end

    def text : String
      @text
    end

    def text=(@text : String) : Nil
      count = grapheme_count
      @cursor = count if @cursor > count
    end

    def cursor : Int32
      @cursor
    end

    def cursor=(pos : Int32) : Nil
      @cursor = pos.clamp(0, grapheme_count)
    end

    property on_submit : (String -> Nil)?

    def draw(canvas : Ansi::Canvas) : Nil
      p = canvas.panel(x, y, w: width, h: height)
      if b = border
        p = p.border(b, style)
      end
      p = p.shadow if shadow
      p.fill(style).draw

      draw_text(canvas)
    end

    def handle_event(event : Ansi::Event) : Bool
      case event
      when Ansi::Key
        handle_key(event)
      when Ansi::Mouse
        if event.button.left? && event.action.press? && hit?(event.x, event.y)
          click_to_cursor(event.x)
          return true
        end
        false
      else
        false
      end
    end

    private def handle_key(key : Ansi::Key) : Bool
      case key.code
      when .char?
        insert_text(key.char)
        true
      when .backspace?
        delete_before
        true
      when .delete?
        delete_at
        true
      when .left?
        self.cursor = @cursor - 1
        true
      when .right?
        self.cursor = @cursor + 1
        true
      when .home?
        @cursor = 0
        true
      when .end?
        @cursor = grapheme_count
        true
      when .enter?
        @on_submit.try(&.call(@text))
        true
      else
        false
      end
    end

    private def draw_text(canvas : Ansi::Canvas) : Nil
      tx = content_x + @pad
      tw = content_width - @pad * 2
      return if tw <= 0

      ensure_cursor_visible(tw)

      col = 0
      gi = 0
      Ansi::Graphemes.each(@text) do |grapheme|
        gw = Ansi::DisplayWidth.of(grapheme)
        dcol = col - @scroll

        if dcol >= 0 && dcol + gw <= tw
          s = (gi == @cursor && focused?) ? style.merge(@cursor_style) : style
          canvas.put(tx + dcol, content_y, grapheme, s)
        end

        col += gw
        gi += 1
      end

      # Draw cursor at end of text
      if gi == @cursor && focused?
        dcol = col - @scroll
        if dcol >= 0 && dcol < tw
          canvas.put(tx + dcol, content_y, " ", style.merge(@cursor_style))
        end
      end
    end

    private def ensure_cursor_visible(text_width : Int32) : Nil
      cursor_col = display_width_to(@cursor)
      if cursor_col < @scroll
        @scroll = cursor_col
      end
      if cursor_col - @scroll >= text_width
        @scroll = cursor_col - text_width + 1
      end
    end

    private def click_to_cursor(mouse_x : Int32) : Nil
      tx = content_x + @pad
      target = mouse_x - tx + @scroll
      col = 0
      gi = 0
      Ansi::Graphemes.each(@text) do |grapheme|
        gw = Ansi::DisplayWidth.of(grapheme)
        if col + gw > target
          @cursor = gi
          return
        end
        col += gw
        gi += 1
      end
      @cursor = gi
    end

    private def grapheme_count : Int32
      count = 0
      Ansi::Graphemes.each(@text) { |_| count += 1 }
      count
    end

    private def display_width_to(index : Int32) : Int32
      col = 0
      i = 0
      Ansi::Graphemes.each(@text) do |g|
        break if i >= index
        col += Ansi::DisplayWidth.of(g)
        i += 1
      end
      col
    end

    private def insert_text(char : String) : Nil
      gs = to_graphemes
      gs.insert(@cursor, char)
      @text = gs.join
      @cursor += 1
    end

    private def delete_before : Nil
      return if @cursor == 0
      gs = to_graphemes
      gs.delete_at(@cursor - 1)
      @text = gs.join
      @cursor -= 1
    end

    private def delete_at : Nil
      gs = to_graphemes
      return if @cursor >= gs.size
      gs.delete_at(@cursor)
      @text = gs.join
    end

    private def to_graphemes : Array(String)
      result = [] of String
      Ansi::Graphemes.each(@text) { |g| result << g }
      result
    end
  end
end
