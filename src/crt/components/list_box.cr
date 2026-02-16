module CRT
  class ListBox < Widget
    def self.default_theme : Theme
      CRT.theme.copy_with(unfocused: Ansi::Style.default)
    end

    @items : Array(String)
    @selected : Int32
    @scroll_y : Int32
    @marker : String
    @marker_w : Int32
    @on_change : (Int32 -> Nil)?

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   @items : Array(String),
                   @selected : Int32 = 0,
                   width : Int32? = nil, height : Int32? = nil,
                   style : Ansi::Style = CRT.theme.base,
                   @marker : String = "▸",
                   border : Ansi::Border? = Ansi::Border::Single,
                   decor : Decor = Decor::None,
                   theme : Theme = ListBox.default_theme,
                   &on_change : Int32 ->)
      @on_change = on_change
      @scroll_y = 0
      @marker_w = Ansi::DisplayWidth.width(@marker)
      @selected = @selected.clamp(0, @items.size - 1)
      w, h = compute_size(border)
      super(screen, x: x, y: y, width: width || w, height: height || h,
            style: style, border: border, decor: decor, focusable: true,
            theme: theme)
      ensure_visible
    end

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   @items : Array(String),
                   @selected : Int32 = 0,
                   width : Int32? = nil, height : Int32? = nil,
                   style : Ansi::Style = CRT.theme.base,
                   @marker : String = "▸",
                   border : Ansi::Border? = Ansi::Border::Single,
                   decor : Decor = Decor::None,
                   theme : Theme = ListBox.default_theme)
      @on_change = nil
      @scroll_y = 0
      @marker_w = Ansi::DisplayWidth.width(@marker)
      @selected = @selected.clamp(0, @items.size - 1)
      w, h = compute_size(border)
      super(screen, x: x, y: y, width: width || w, height: height || h,
            style: style, border: border, decor: decor, focusable: true,
            theme: theme)
      ensure_visible
    end

    getter items : Array(String)
    getter selected : Int32
    getter scroll_y : Int32

    def selected=(index : Int32) : Nil
      @selected = index.clamp(0, @items.size - 1)
      ensure_visible
    end

    def selected_item : String
      @items[@selected]
    end

    property on_change : (Int32 -> Nil)?

    def select(index : Int32) : Nil
      index = index.clamp(0, @items.size - 1)
      return if index == @selected
      @selected = index
      ensure_visible
      @on_change.try(&.call(@selected))
    end

    def draw(canvas : Ansi::Canvas) : Nil
      panel(canvas).fill(style).draw

      visible = content_height
      visible.times do |row|
        i = @scroll_y + row
        break if i >= @items.size
        is_selected = i == @selected
        prefix = is_selected ? @marker : " " * @marker_w
        display = "#{prefix} #{@items[i]}"
        s = theme.resolve(style, focused: is_selected && focused?, active: is_selected)
        canvas.write(content_x, content_y + row, display, s)
      end
    end

    def handle_event(event : Ansi::Event) : Bool
      case event
      when Ansi::Key
        if event.code.up?
          select_prev
          return true
        elsif event.code.down?
          select_next
          return true
        elsif event.code.home?
          self.select(0)
          return true
        elsif event.code.end?
          self.select(@items.size - 1)
          return true
        elsif event.code.enter? || (event.code.char? && event.char == " ")
          @on_change.try(&.call(@selected))
          return true
        end
      when Ansi::Mouse
        if event.button.left? && event.action.press? && hit?(event.x, event.y)
          click_index = (event.y - content_y) + @scroll_y
          if click_index >= 0 && click_index < @items.size
            self.select(click_index)
          end
          return true
        end
      end
      false
    end

    private def select_next : Nil
      self.select(@selected + 1) if @selected < @items.size - 1
    end

    private def select_prev : Nil
      self.select(@selected - 1) if @selected > 0
    end

    private def ensure_visible : Nil
      visible = content_height
      if @selected < @scroll_y
        @scroll_y = @selected
      elsif @selected >= @scroll_y + visible
        @scroll_y = @selected - visible + 1
      end
    end

    private def compute_size(border : Ansi::Border?) : {Int32, Int32}
      max_item_w = Ansi::DisplayWidth.max_width(@items)
      inset = border ? 2 : 0
      w = @marker_w + 1 + max_item_w + inset
      h = @items.size + inset
      {w, h}
    end
  end
end
