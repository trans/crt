module CRT
  class RadioGroup < Widget
    @items : Array(String)
    @selected : Int32
    @selected_mark : String
    @unselected_mark : String
    @focus_style : Ansi::Style
    @on_change : (Int32 -> Nil)?

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   @items : Array(String),
                   @selected : Int32 = 0,
                   width : Int32? = nil, height : Int32? = nil,
                   style : Ansi::Style = Ansi::Style.default,
                   @focus_style : Ansi::Style = Ansi::Style::INVERSE,
                   @selected_mark : String = "(●)",
                   @unselected_mark : String = "( )",
                   border : Ansi::Border? = nil,
                   shadow : Bool = false,
                   &on_change : Int32 ->)
      @on_change = on_change
      @selected = @selected.clamp(0, @items.size - 1)
      w, h = compute_size(border)
      super(screen, x: x, y: y, width: width || w, height: height || h,
            style: style, border: border, shadow: shadow, focusable: true)
    end

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   @items : Array(String),
                   @selected : Int32 = 0,
                   width : Int32? = nil, height : Int32? = nil,
                   style : Ansi::Style = Ansi::Style.default,
                   @focus_style : Ansi::Style = Ansi::Style::INVERSE,
                   @selected_mark : String = "(●)",
                   @unselected_mark : String = "( )",
                   border : Ansi::Border? = nil,
                   shadow : Bool = false)
      @on_change = nil
      @selected = @selected.clamp(0, @items.size - 1)
      w, h = compute_size(border)
      super(screen, x: x, y: y, width: width || w, height: height || h,
            style: style, border: border, shadow: shadow, focusable: true)
    end

    getter items : Array(String)
    getter selected : Int32

    def selected=(index : Int32) : Nil
      @selected = index.clamp(0, @items.size - 1)
    end

    def selected_item : String
      @items[@selected]
    end

    property on_change : (Int32 -> Nil)?

    def select(index : Int32) : Nil
      index = index.clamp(0, @items.size - 1)
      return if index == @selected
      @selected = index
      @on_change.try(&.call(@selected))
    end

    def draw(canvas : Ansi::Canvas) : Nil
      p = canvas.panel(x, y, w: width, h: height)
      if b = border
        p = p.border(b, style)
      end
      p = p.shadow if shadow
      p.fill(style).draw

      @items.each_with_index do |item, i|
        mark = i == @selected ? @selected_mark : @unselected_mark
        display = "#{mark} #{item}"
        s = (i == @selected && focused?) ? style.merge(@focus_style) : style
        canvas.write(content_x, content_y + i, display, s)
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
        elsif event.code.enter? || (event.code.char? && event.char == " ")
          @on_change.try(&.call(@selected))
          return true
        end
      when Ansi::Mouse
        if event.button.left? && event.action.press? && hit?(event.x, event.y)
          click_index = event.y - content_y
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

    private def compute_size(border : Ansi::Border?) : {Int32, Int32}
      mark_w = {Ansi::DisplayWidth.width(@selected_mark),
                Ansi::DisplayWidth.width(@unselected_mark)}.max
      max_item_w = @items.max_of { |i| Ansi::DisplayWidth.width(i) }
      inset = border ? 2 : 0
      w = mark_w + 1 + max_item_w + inset
      h = @items.size + inset
      {w, h}
    end
  end
end
