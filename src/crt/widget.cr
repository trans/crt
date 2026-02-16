module CRT
  # TODO: Consider constraint-based layout as an alternative/complement to
  # container flow layout. API idea: `entry.edge.bottom == (label.edge.top + 1)`
  # using overloaded `==` to create bindings, resolved via topological sort.
  #
  # TODO: Add free-form boxes and lines to Boxing system — standalone horizontal
  # and vertical line segments that participate in intersection resolution without
  # being tied to a widget border.
  abstract class Widget
    getter screen : Screen
    property x : Int32
    property y : Int32
    property width : Int32
    property height : Int32
    property style : Ansi::Style
    property border : Ansi::Border?
    property shadow : Bool
    getter? visible : Bool
    getter? focusable : Bool
    getter? focused : Bool
    getter box : Ansi::Boxing?
    getter theme : Theme

    def initialize(@screen : Screen, *, @x : Int32, @y : Int32,
                   @width : Int32, @height : Int32,
                   @style : Ansi::Style = Ansi::Style.default,
                   @border : Ansi::Border? = nil,
                   @shadow : Bool = false,
                   @visible : Bool = true,
                   @focusable : Bool = false,
                   @box : Ansi::Boxing? = nil,
                   @theme : Theme = Theme.new)
      @focused = false
      register_boxing
      @screen.register(self)
    end

    abstract def draw(canvas : Ansi::Canvas) : Nil

    # Drawn after Boxing borders — use for content that overlays borders (e.g. titles).
    def draw_overlay(canvas : Ansi::Canvas) : Nil
    end

    def handle_event(event : Ansi::Event) : Bool
      false
    end

    def focus(direction : Int32 = 1) : Nil
      @focused = true
    end

    def unfocus : Nil
      @focused = false
    end

    def show : Nil
      @visible = true
    end

    def hide : Nil
      @visible = false
    end

    def destroy : Nil
      unregister_boxing
      @screen.unregister(self)
    end

    def self.open(screen : Screen, **kwargs, &)
      widget = new(screen, **kwargs)
      begin
        yield widget
      ensure
        widget.destroy
      end
    end

    # Pre-configured panel from widget properties.
    def panel(canvas : Ansi::Canvas) : Ansi::Panel
      p = canvas.panel(x, y, w: width, h: height)
      if bx = @box
        # Boxing draws the border — but set it on panel for fill/text inset.
        unless @border == Ansi::Border::None
          p = p.border(bx.border, style)
        end
      elsif b = border
        p = p.border(b, style)
      end
      p = p.shadow if shadow
      p
    end

    # Returns true if the point (mx, my) is within the widget bounds.
    def hit?(mx : Int32, my : Int32) : Bool
      mx >= x && mx < x + width && my >= y && my < y + height
    end

    # Content area inset by border.
    def content_x : Int32
      x + border_size
    end

    def content_y : Int32
      y + border_size
    end

    def content_width : Int32
      width - border_size * 2
    end

    def content_height : Int32
      height - border_size * 2
    end

    private def border_size : Int32
      if @box
        @border == Ansi::Border::None ? 0 : 1
      else
        @border ? 1 : 0
      end
    end

    private def register_boxing : Nil
      box = @box
      return unless box
      return if @border == Ansi::Border::None
      box.add(x: @x, y: @y, w: @width, h: @height)
      @screen.track_boxing(box)
    end

    private def unregister_boxing : Nil
      box = @box
      return unless box
      return if @border == Ansi::Border::None
      box.remove(x: @x, y: @y, w: @width, h: @height)
    end

    protected def reregister_boxing(old_x : Int32, old_y : Int32,
                                    old_w : Int32, old_h : Int32) : Nil
      box = @box
      return unless box
      return if @border == Ansi::Border::None
      box.remove(x: old_x, y: old_y, w: old_w, h: old_h)
      box.add(x: @x, y: @y, w: @width, h: @height)
    end
  end
end
