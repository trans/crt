module CRT
  # TODO: Add word/char wrap support. Requires reflow on edit — wrapped line
  # count changes per keystroke, and logical-to-visual cursor mapping.
  class EntryBox < Widget
    @lines : Array(Ansi::EditLine)
    @cursor_line : Int32
    @scroll_y : Int32
    @target_col : Int32?
    @cursor_style : Ansi::Style
    @scrollbar : Bool
    @thumb_style : Ansi::Style
    @track_style : Ansi::Style
    @on_change : (String -> Nil)?

    def self.default_theme : Theme
      CRT.theme.copy_with(
        focused: Ansi::Style.new(bg: Ansi::Color.rgb(255, 255, 255)),
        unfocused: Ansi::Style.default)
    end

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   width : Int32, height : Int32,
                   text : String = "",
                   @cursor_style : Ansi::Style = Ansi::Style::INVERSE,
                   @scrollbar : Bool = false,
                   @thumb_style : Ansi::Style = Slider::THUMB_DEFAULT,
                   @track_style : Ansi::Style = Slider::TRACK_DEFAULT,
                   style : Ansi::Style = CRT.theme.field_style,
                   border : Ansi::Border? = nil,
                   decor : Decor = Decor::None,
                   theme : Theme = EntryBox.default_theme,
                   &on_change : String ->)
      @on_change = on_change
      @cursor_line = 0
      @scroll_y = 0
      @target_col = nil
      @lines = text.split('\n').map { |l| Ansi::EditLine.new(l) }
      @lines << Ansi::EditLine.new("") if @lines.empty?
      super(screen, x: x, y: y, width: width, height: height,
            style: style, border: border, decor: decor, focusable: true,
            theme: theme)
    end

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   width : Int32, height : Int32,
                   text : String = "",
                   @cursor_style : Ansi::Style = Ansi::Style::INVERSE,
                   @scrollbar : Bool = false,
                   @thumb_style : Ansi::Style = Slider::THUMB_DEFAULT,
                   @track_style : Ansi::Style = Slider::TRACK_DEFAULT,
                   style : Ansi::Style = CRT.theme.field_style,
                   border : Ansi::Border? = nil,
                   decor : Decor = Decor::None,
                   theme : Theme = EntryBox.default_theme)
      @on_change = nil
      @cursor_line = 0
      @scroll_y = 0
      @target_col = nil
      @lines = text.split('\n').map { |l| Ansi::EditLine.new(l) }
      @lines << Ansi::EditLine.new("") if @lines.empty?
      super(screen, x: x, y: y, width: width, height: height,
            style: style, border: border, decor: decor, focusable: true,
            theme: theme)
    end

    def text : String
      @lines.map(&.text).join('\n')
    end

    def text=(value : String) : Nil
      @lines = value.split('\n').map { |l| Ansi::EditLine.new(l) }
      @lines << Ansi::EditLine.new("") if @lines.empty?
      @cursor_line = 0
      @scroll_y = 0
      @target_col = nil
      @lines[0].move_home
    end

    getter cursor_line : Int32
    getter scroll_y : Int32

    def cursor_col : Int32
      @lines[@cursor_line].cursor
    end

    def line_count : Int32
      @lines.size
    end

    property on_change : (String -> Nil)?

    def draw(canvas : Ansi::Canvas) : Nil
      fill_style = theme.resolve(style, focused: focused?)
      panel(canvas).fill(fill_style).draw

      avail_w = content_width
      show_sb = @scrollbar && needs_v_scroll?
      avail_w -= 1 if show_sb
      visible_h = content_height

      visible_h.times do |row|
        i = @scroll_y + row
        break if i >= @lines.size
        cs = (i == @cursor_line && focused?) ? fill_style.merge(@cursor_style) : nil
        @lines[i].render(canvas, content_x, content_y + row, avail_w, fill_style, cs)
      end

      draw_scrollbar(canvas) if show_sb
    end

    def handle_event(event : Ansi::Event) : Bool
      case event
      when Ansi::Key
        current = @lines[@cursor_line]
        if event.code.char?
          current.insert(event.char.to_s)
          @target_col = nil
          fire_change
          return true
        elsif event.code.backspace?
          if current.cursor > 0
            current.delete_before
          elsif @cursor_line > 0
            join_with_previous
          end
          @target_col = nil
          fire_change
          return true
        elsif event.code.delete?
          if current.cursor < current.grapheme_count
            current.delete_at
          elsif @cursor_line < @lines.size - 1
            join_with_next
          end
          @target_col = nil
          fire_change
          return true
        elsif event.code.enter?
          split_line
          @target_col = nil
          fire_change
          return true
        elsif event.code.up?
          move_up
          return true
        elsif event.code.down?
          move_down
          return true
        elsif event.code.left?
          if current.cursor > 0
            current.move_left
          elsif @cursor_line > 0
            @cursor_line -= 1
            @lines[@cursor_line].move_end
            ensure_cursor_visible
          end
          @target_col = nil
          return true
        elsif event.code.right?
          if current.cursor < current.grapheme_count
            current.move_right
          elsif @cursor_line < @lines.size - 1
            @cursor_line += 1
            @lines[@cursor_line].move_home
            ensure_cursor_visible
          end
          @target_col = nil
          return true
        elsif event.code.home?
          current.move_home
          @target_col = nil
          return true
        elsif event.code.end?
          current.move_end
          @target_col = nil
          return true
        elsif event.code.page_up?
          move_up(content_height)
          return true
        elsif event.code.page_down?
          move_down(content_height)
          return true
        end
      when Ansi::Mouse
        if event.button.left? && event.action.press? && hit?(event.x, event.y)
          clicked_line = (event.y - content_y) + @scroll_y
          if clicked_line >= 0 && clicked_line < @lines.size
            @cursor_line = clicked_line
            @lines[@cursor_line].move_to_column(event.x - content_x + @lines[@cursor_line].scroll)
            ensure_cursor_visible
          end
          @target_col = nil
          return true
        end
      end
      false
    end

    private def move_up(n : Int32 = 1) : Nil
      return if @cursor_line == 0
      @target_col ||= @lines[@cursor_line].cursor_column
      @cursor_line = {@cursor_line - n, 0}.max
      @lines[@cursor_line].move_to_column(@target_col.not_nil!)
      ensure_cursor_visible
    end

    private def move_down(n : Int32 = 1) : Nil
      return if @cursor_line >= @lines.size - 1
      @target_col ||= @lines[@cursor_line].cursor_column
      @cursor_line = {@cursor_line + n, @lines.size - 1}.min
      @lines[@cursor_line].move_to_column(@target_col.not_nil!)
      ensure_cursor_visible
    end

    private def split_line : Nil
      current = @lines[@cursor_line]
      graphemes = Ansi::Graphemes.to_a(current.text)
      before = graphemes[0...current.cursor].join
      after = graphemes[current.cursor..].join
      current.text = before
      current.move_end
      @lines.insert(@cursor_line + 1, Ansi::EditLine.new(after))
      @cursor_line += 1
      @lines[@cursor_line].move_home
      ensure_cursor_visible
    end

    private def join_with_previous : Nil
      return if @cursor_line == 0
      current_text = @lines[@cursor_line].text
      @lines.delete_at(@cursor_line)
      @cursor_line -= 1
      prev = @lines[@cursor_line]
      prev.move_end
      join_col = prev.cursor
      Ansi::Graphemes.each(current_text) { |g| prev.insert(g) }
      prev.cursor = join_col
      ensure_cursor_visible
    end

    private def join_with_next : Nil
      return if @cursor_line >= @lines.size - 1
      next_text = @lines[@cursor_line + 1].text
      @lines.delete_at(@cursor_line + 1)
      current = @lines[@cursor_line]
      current.move_end
      Ansi::Graphemes.each(next_text) { |g| current.insert(g) }
    end

    private def ensure_cursor_visible : Nil
      visible_h = content_height
      if @cursor_line < @scroll_y
        @scroll_y = @cursor_line
      elsif @cursor_line >= @scroll_y + visible_h
        @scroll_y = @cursor_line - visible_h + 1
      end
    end

    private def needs_v_scroll? : Bool
      @lines.size > content_height
    end

    private def fire_change : Nil
      @on_change.try(&.call(text))
    end

    private def draw_scrollbar(canvas : Ansi::Canvas) : Nil
      sb_x = content_x + content_width - 1
      visible_h = content_height
      total = @lines.size
      half_cells = visible_h * 2

      thumb_h = {(visible_h.to_f / total * half_cells).round.to_i, 2}.max
      max_scroll = total - visible_h
      max_pos = {half_cells - thumb_h, 0}.max
      thumb_pos = max_scroll > 0 ? (@scroll_y * max_pos) // max_scroll : 0

      thumb_bg = focused? ? @thumb_style.bg : Slider::THUMB_DIM.bg
      track_bg = @track_style.bg
      full_thumb_s = Ansi::Style.new(bg: thumb_bg)
      full_track_s = Ansi::Style.new(bg: track_bg)
      half_s = Ansi::Style.new(fg: thumb_bg, bg: track_bg)

      visible_h.times do |row|
        top = row * 2
        bot = row * 2 + 1
        in_top = top >= thumb_pos && top < thumb_pos + thumb_h
        in_bot = bot >= thumb_pos && bot < thumb_pos + thumb_h
        if in_top && in_bot
          canvas.put(sb_x, content_y + row, " ", full_thumb_s)
        elsif in_top
          canvas.put(sb_x, content_y + row, "▀", half_s)
        elsif in_bot
          canvas.put(sb_x, content_y + row, "▄", half_s)
        else
          canvas.put(sb_x, content_y + row, " ", full_track_s)
        end
      end
    end
  end
end
