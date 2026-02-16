module CRT
  class ItemList < Widget
    THEME_DEFAULT = Theme.new(
      focused: Ansi::Style::INVERSE,
      unfocused: Ansi::Style.new(dim: true, inverse: true))

    @items : Array(String)
    @selected : Int32
    @left_mark : String
    @right_mark : String
    @pad : Int32
    @on_change : (Int32 -> Nil)?

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   @items : Array(String),
                   @selected : Int32 = 0,
                   width : Int32? = nil, height : Int32? = nil,
                   style : Ansi::Style = Ansi::Style.default,
                   @left_mark : String = "◄",
                   @right_mark : String = "►",
                   @pad : Int32 = 1,
                   border : Ansi::Border? = nil,
                   shadow : Bool = false,
                   theme : Theme = THEME_DEFAULT,
                   &on_change : Int32 ->)
      @on_change = on_change
      @selected = @selected.clamp(0, @items.size - 1)
      w, h = compute_size(border)
      super(screen, x: x, y: y, width: width || w, height: height || h,
            style: style, border: border, shadow: shadow, focusable: true,
            theme: theme)
    end

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   @items : Array(String),
                   @selected : Int32 = 0,
                   width : Int32? = nil, height : Int32? = nil,
                   style : Ansi::Style = Ansi::Style.default,
                   @left_mark : String = "◄",
                   @right_mark : String = "►",
                   @pad : Int32 = 1,
                   border : Ansi::Border? = nil,
                   shadow : Bool = false,
                   theme : Theme = THEME_DEFAULT)
      @on_change = nil
      @selected = @selected.clamp(0, @items.size - 1)
      w, h = compute_size(border)
      super(screen, x: x, y: y, width: width || w, height: height || h,
            style: style, border: border, shadow: shadow, focusable: true,
            theme: theme)
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
      index = index % @items.size
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

      lm_w = Ansi::DisplayWidth.width(@left_mark)
      rm_w = Ansi::DisplayWidth.width(@right_mark)
      item_area_w = content_width - lm_w - rm_w - @pad * 2

      cy = content_y
      # Left mark
      canvas.write(content_x, cy, @left_mark, style)
      # Item text — pad + centered item + pad, all in resolved style
      item = @items[@selected]
      item_w = Ansi::DisplayWidth.width(item)
      pad_total = item_area_w - item_w
      pad_left = {pad_total // 2, 0}.max
      pad_right = {pad_total - pad_left, 0}.max
      padded = " " * @pad + " " * pad_left + item + " " * pad_right + " " * @pad
      resolved = theme.resolve(style, focused: focused?)
      canvas.write(content_x + lm_w, cy, padded, resolved)
      # Right mark
      canvas.write(content_x + content_width - rm_w, cy, @right_mark, style)
    end

    def handle_event(event : Ansi::Event) : Bool
      case event
      when Ansi::Key
        if event.code.right?
          self.select((@selected + 1) % @items.size)
          return true
        elsif event.code.left?
          self.select((@selected - 1) % @items.size)
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
          lm_w = Ansi::DisplayWidth.width(@left_mark)
          rm_w = Ansi::DisplayWidth.width(@right_mark)
          rel_x = event.x - content_x
          if rel_x < lm_w + @pad
            self.select((@selected - 1) % @items.size)
          elsif rel_x >= content_width - rm_w - @pad
            self.select((@selected + 1) % @items.size)
          end
          return true
        end
      end
      false
    end

    private def compute_size(border : Ansi::Border?) : {Int32, Int32}
      lm_w = Ansi::DisplayWidth.width(@left_mark)
      rm_w = Ansi::DisplayWidth.width(@right_mark)
      max_item_w = Ansi::DisplayWidth.max_width(@items)
      inset = border ? 2 : 0
      w = lm_w + @pad + max_item_w + @pad + rm_w + inset
      h = 1 + inset
      {w, h}
    end
  end
end
