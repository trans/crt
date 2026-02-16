module CRT
  class TextBox < Widget
    @text : String
    @lines : Array(String)
    @scroll_y : Int32
    @scroll_x : Int32
    @wrap : Ansi::Wrap
    @scrollbar : Bool
    @thumb_style : Ansi::Style
    @track_style : Ansi::Style

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   width : Int32, height : Int32,
                   @text : String = "",
                   @wrap : Ansi::Wrap = Ansi::Wrap::Word,
                   @scrollbar : Bool = false,
                   @thumb_style : Ansi::Style = Slider::THUMB_DEFAULT,
                   @track_style : Ansi::Style = Slider::TRACK_DEFAULT,
                   style : Ansi::Style = CRT.theme.base,
                   border : Ansi::Border? = nil,
                   decor : Decor = Decor::None)
      @scroll_y = 0
      @scroll_x = 0
      @lines = [] of String
      super(screen, x: x, y: y, width: width, height: height,
            style: style, border: border, decor: decor, focusable: true)
      @lines = compute_lines
    end

    getter text : String
    getter scroll_y : Int32
    getter scroll_x : Int32

    def text=(value : String) : Nil
      @text = value
      @lines = compute_lines
      clamp_scroll
    end

    def line_count : Int32
      @lines.size
    end

    def scroll_to(y : Int32, x : Int32 = 0) : Nil
      @scroll_y = y
      @scroll_x = x
      clamp_scroll
    end

    def draw(canvas : Ansi::Canvas) : Nil
      panel(canvas).fill(style).draw

      avail_w = content_width
      show_sb = @scrollbar && needs_v_scroll?
      avail_w -= 1 if show_sb
      visible_h = content_height

      visible_h.times do |row|
        i = @scroll_y + row
        break if i >= @lines.size
        line = @lines[i]
        if @wrap.none?
          write_scrolled_line(canvas, content_x, content_y + row, line, avail_w)
        else
          canvas.write(content_x, content_y + row, line, style)
        end
      end

      draw_scrollbar(canvas) if show_sb
    end

    def handle_event(event : Ansi::Event) : Bool
      case event
      when Ansi::Key
        if event.code.up?
          scroll_up(1)
          return true
        elsif event.code.down?
          scroll_down(1)
          return true
        elsif event.code.page_up?
          scroll_up(content_height)
          return true
        elsif event.code.page_down?
          scroll_down(content_height)
          return true
        elsif event.code.home?
          @scroll_y = 0
          @scroll_x = 0
          return true
        elsif event.code.end?
          @scroll_y = {@lines.size - content_height, 0}.max
          return true
        elsif @wrap.none? && event.code.left?
          @scroll_x = {@scroll_x - 1, 0}.max
          return true
        elsif @wrap.none? && event.code.right?
          max_x = {max_line_width - content_width + 1, 0}.max
          @scroll_x = {@scroll_x + 1, max_x}.min
          return true
        end
      end
      false
    end

    private def scroll_up(n : Int32) : Nil
      @scroll_y = {@scroll_y - n, 0}.max
    end

    private def scroll_down(n : Int32) : Nil
      max = {@lines.size - content_height, 0}.max
      @scroll_y = {@scroll_y + n, max}.min
    end

    private def clamp_scroll : Nil
      max_y = {@lines.size - content_height, 0}.max
      @scroll_y = @scroll_y.clamp(0, max_y)
      if @wrap.none?
        max_x = {max_line_width - content_width + 1, 0}.max
        @scroll_x = @scroll_x.clamp(0, max_x)
      else
        @scroll_x = 0
      end
    end

    private def needs_v_scroll? : Bool
      @lines.size > content_height
    end

    private def max_line_width : Int32
      return 0 if @lines.empty?
      Ansi::DisplayWidth.max_width(@lines)
    end

    private def avail_width : Int32
      w = content_width
      w -= 1 if @scrollbar
      w
    end

    private def compute_lines : Array(String)
      case @wrap
      when .none?
        @text.split('\n')
      when .char?
        wrap_char(@text, avail_width)
      when .word?
        wrap_word(@text, avail_width)
      else
        @text.split('\n')
      end
    end

    private def wrap_char(text : String, width : Int32) : Array(String)
      result = [] of String
      text.split('\n').each do |raw_line|
        if raw_line.empty?
          result << ""
          next
        end
        line = String::Builder.new
        line_w = 0
        Ansi::Graphemes.each(raw_line) do |g|
          gw = Ansi::DisplayWidth.of(g)
          if line_w + gw > width && line_w > 0
            result << line.to_s
            line = String::Builder.new
            line_w = 0
          end
          line << g
          line_w += gw
        end
        result << line.to_s
      end
      result
    end

    private def wrap_word(text : String, width : Int32) : Array(String)
      result = [] of String
      text.split('\n').each do |raw_line|
        if raw_line.empty?
          result << ""
          next
        end
        words = raw_line.split(/(\s+)/)
        line = String::Builder.new
        line_w = 0
        words.each do |word|
          ww = Ansi::DisplayWidth.width(word)
          if line_w == 0
            line << word
            line_w = ww
          elsif line_w + ww <= width
            line << word
            line_w += ww
          else
            result << line.to_s
            line = String::Builder.new
            line << word.lstrip
            line_w = Ansi::DisplayWidth.width(word.lstrip)
          end
        end
        result << line.to_s
      end
      result
    end

    private def write_scrolled_line(canvas : Ansi::Canvas, x : Int32, y : Int32,
                                     line : String, avail_w : Int32) : Nil
      col = 0
      written = 0
      Ansi::Graphemes.each(line) do |grapheme|
        gw = Ansi::DisplayWidth.of(grapheme)
        if col >= @scroll_x && written + gw <= avail_w
          canvas.put(x + written, y, grapheme, style)
          written += gw
        elsif col >= @scroll_x
          break
        end
        col += gw
      end
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
