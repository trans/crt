module CRT
  class Tabs < Widget
    record Page, label : String, frame : Frame

    def self.default_theme : Theme
      CRT.theme.copy_with(
        focused: Ansi::Style.new(bg: Ansi::Color.rgb(255, 255, 255)),
        unfocused: Ansi::Style.default,
        active: CRT.theme.field_style,
        passive: Ansi::Style.default)
    end

    @pages : Array(Page)
    @active : Int32
    @in_page : Bool
    @separator : Bool
    property tab_type : TabType

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   width : Int32, height : Int32,
                   style : Ansi::Style = CRT.theme.base,
                   border : Ansi::Border? = nil,
                   decor : Decor = Decor::None,
                   box : Ansi::Boxing? = nil,
                   @separator : Bool = false,
                   @tab_type : TabType = TabType::Folder,
                   theme : Theme = Tabs.default_theme)
      @pages = [] of Page
      @active = 0
      @in_page = false
      super(screen, x: x, y: y, width: width, height: height,
            style: style, border: border, decor: decor,
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
      # Extend bevel to top-right for underline style
      if @tab_type.underline? && decor.bevel?
        canvas.put(x + width, y, "▎", Ansi::Style.new(fg: Ansi::Color.rgb(70, 70, 85)))
      end

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
      content_x + 2
    end

    private def page_y : Int32
      content_y + 2 + (@separator ? 1 : 0)
    end

    private def page_width : Int32
      content_width - 2
    end

    private def page_height : Int32
      content_height - 2 - (@separator ? 1 : 0)
    end

    # Tab bar rendering

    private def draw_tab_bar(canvas : Ansi::Canvas) : Nil
      case @tab_type
      when .folder?
        draw_tab_bar_folder(canvas)
      when .underline?
        draw_tab_bar_underline(canvas)
      end
    end

    private def draw_tab_bar_folder(canvas : Ansi::Canvas) : Nil
      cx = content_x
      @pages.each_with_index do |page, i|
        if i > 0
          canvas.put(cx, content_y, "│", Ansi::Style.new(fg: Ansi::Color.rgb(70, 70, 85), bg: style.bg))
          cx += 1
        end
        is_active = i == @active
        s = theme.resolve(style, focused: focused? && !@in_page && is_active, active: is_active)
        text = " #{page.label} "
        canvas.write(cx, content_y, text, s)
        cx += Ansi::DisplayWidth.width(text)
      end
      # Clear remaining cells to default background
      right_edge = content_x + content_width
      while cx < right_edge
        canvas.put(cx, content_y, " ", Ansi::Style.default)
        cx += 1
      end
    end

    private def draw_tab_bar_underline(canvas : Ansi::Canvas) : Nil
      cx = content_x
      label_ranges = [] of {Int32, Int32}
      @pages.each_with_index do |page, i|
        is_active = i == @active
        label_w = Ansi::DisplayWidth.width(page.label)
        text = " #{page.label} "
        text_w = Ansi::DisplayWidth.width(text)
        label_ranges << {cx + 1, cx + 1 + label_w}
        s = is_active ? style.merge(Ansi::Style.new(bold: true)) : style
        canvas.write(cx, content_y, text, s)
        cx += text_w
      end
      # Clear remaining cells
      right_edge = content_x + content_width
      while cx < right_edge
        canvas.put(cx, content_y, " ", style)
        cx += 1
      end
      # Draw underline
      line_y = content_y + 1
      active_range = @active < label_ranges.size ? label_ranges[@active] : nil
      dim_line = Ansi::Style.new(fg: Ansi::Color.rgb(100, 100, 120), bg: style.bg)
      bright_line = if focused? && !@in_page
                      Ansi::Style.new(fg: Ansi::Color.rgb(255, 255, 255), bg: style.bg)
                    else
                      Ansi::Style.new(fg: theme.base.fg, bg: style.bg)
                    end
      content_width.times do |i|
        lx = content_x + i
        in_active = active_range && lx >= active_range[0] && lx < active_range[1]
        canvas.put(lx, line_y, "─", in_active ? bright_line : dim_line)
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
