module CRT
  class Tabs < Widget
    record Page, label : String, frame : Frame

    THEME_DEFAULT = Theme.new(active: Ansi::Style::INVERSE)

    @pages : Array(Page)
    @active : Int32
    @in_page : Bool
    @separator : Bool

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   width : Int32, height : Int32,
                   style : Ansi::Style = Ansi::Style.default,
                   border : Ansi::Border? = nil,
                   shadow : Bool = false,
                   box : Ansi::Boxing? = nil,
                   @separator : Bool = true,
                   theme : Theme = THEME_DEFAULT)
      @pages = [] of Page
      @active = 0
      @in_page = false
      super(screen, x: x, y: y, width: width, height: height,
            style: style, border: border, shadow: shadow,
            focusable: true, box: box, theme: theme)
    end

    def pages : Array(Page)
      @pages
    end

    def active : Int32
      @active
    end

    def active=(index : Int32) : Nil
      return if index < 0 || index >= @pages.size
      return if index == @active
      if @in_page
        active_page.try(&.unfocus)
      end
      @active = index
      if @in_page
        active_page.try(&.focus)
      end
    end

    def active_page : Frame?
      return nil if @pages.empty?
      @pages[@active].frame
    end

    def page(index : Int32) : Frame
      @pages[index].frame
    end

    def add(label : String) : Frame
      frame = Frame.new(@screen, x: page_x, y: page_y,
                        width: page_width, height: page_height,
                        direction: Direction::Column)
      @screen.unregister(frame)
      @pages << Page.new(label: label, frame: frame)
      frame
    end

    # Drawing

    def draw(canvas : Ansi::Canvas) : Nil
      p = panel(canvas)
      p.fill(style).draw
      draw_tab_bar(canvas)
      draw_separator(canvas)

      if page = active_page
        page.draw(canvas)
      end
    end

    # Focus management

    def focus(direction : Int32 = 1) : Nil
      super
      @in_page = false
    end

    def unfocus : Nil
      super
      active_page.try(&.unfocus)
      @in_page = false
    end

    def handle_event(event : Ansi::Event) : Bool
      case event
      when Ansi::Key
        if @in_page
          return handle_page_event(event)
        else
          return handle_tab_bar_event(event)
        end
      end

      if @in_page
        active_page.try(&.handle_event(event)) || false
      else
        false
      end
    end

    def destroy : Nil
      @pages.each { |p| p.frame.destroy }
      @pages.clear
      super
    end

    # Layout helpers

    private def page_x : Int32
      content_x
    end

    private def page_y : Int32
      content_y + 1 + (@separator ? 1 : 0)
    end

    private def page_width : Int32
      content_width
    end

    private def page_height : Int32
      content_height - 1 - (@separator ? 1 : 0)
    end

    # Tab bar rendering

    private def draw_tab_bar(canvas : Ansi::Canvas) : Nil
      cx = content_x + 1
      @pages.each_with_index do |page, i|
        is_active = i == @active
        s = theme.resolve(style, focused: focused?, active: is_active)
        prefix = is_active ? "▸" : " "
        text = "#{prefix}#{page.label} "
        canvas.write(cx, content_y, text, s)
        cx += Ansi::DisplayWidth.width(text)
      end
    end

    private def draw_separator(canvas : Ansi::Canvas) : Nil
      return unless @separator
      sep_y = content_y + 1
      b = effective_border
      hz = b.chars[0]

      if border_size > 0
        # Tee chars at edges
        left_tee, right_tee = tee_chars(b)
        canvas.put(x, sep_y, left_tee, style)
        content_width.times { |i| canvas.put(content_x + i, sep_y, hz, style) }
        canvas.put(x + width - 1, sep_y, right_tee, style)
      else
        content_width.times { |i| canvas.put(content_x + i, sep_y, hz, style) }
      end
    end

    private def effective_border : Ansi::Border
      if bx = @box
        bx.border
      elsif b = @border
        b == Ansi::Border::None ? Ansi::Border::Single : b
      else
        Ansi::Border::Single
      end
    end

    private def tee_chars(b : Ansi::Border) : {String, String}
      case b
      when .single?, .rounded? then {"├", "┤"}
      when .double?            then {"╠", "╣"}
      when .heavy?             then {"┣", "┫"}
      when .ascii?             then {"+", "+"}
      else                          {"├", "┤"}
      end
    end

    # Focus handling

    private def handle_tab_bar_event(event : Ansi::Key) : Bool
      case event.code
      when .left?
        switch_tab(-1)
        return true
      when .right?
        switch_tab(1)
        return true
      when .tab?
        if event.shift?
          # Shift+Tab: exit Tabs backward
          return false
        else
          # Tab: enter active page (or exit if no focusable children)
          return enter_page
        end
      end
      false
    end

    private def handle_page_event(event : Ansi::Key) : Bool
      if event.code.tab?
        page = active_page
        return false unless page

        if page.handle_event(event)
          # Page handled it (cycled within)
          return true
        end

        if event.shift?
          # Past first child — return to tab bar
          page.unfocus
          @in_page = false
          return true
        else
          # Past last child — exit Tabs forward
          page.unfocus
          @in_page = false
          return false
        end
      end

      # Non-Tab key: forward to page
      active_page.try(&.handle_event(event)) || false
    end

    private def switch_tab(direction : Int32) : Nil
      return if @pages.empty?
      new_idx = (@active + direction).clamp(0, @pages.size - 1)
      self.active = new_idx
    end

    private def enter_page : Bool
      page = active_page
      return false unless page
      focusable = page.children.select { |c| c.focusable? && c.visible? }
      return false if focusable.empty?
      @in_page = true
      page.focus
      true
    end
  end
end
