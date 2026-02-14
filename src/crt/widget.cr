module CRT
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

    def initialize(@screen : Screen, *, @x : Int32, @y : Int32,
                   @width : Int32, @height : Int32,
                   @style : Ansi::Style = Ansi::Style.default,
                   @border : Ansi::Border? = nil,
                   @shadow : Bool = false,
                   @visible : Bool = true,
                   @focusable : Bool = false)
      @focused = false
      @screen.register(self)
    end

    abstract def draw(canvas : Ansi::Canvas) : Nil

    def handle_event(event : Ansi::Event) : Bool
      false
    end

    def focus : Nil
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
      if b = border
        p = p.border(b, style)
      end
      p = p.shadow if shadow
      p
    end

    # Content area inset by border.
    def content_x : Int32
      x + (border ? 1 : 0)
    end

    def content_y : Int32
      y + (border ? 1 : 0)
    end

    def content_width : Int32
      width - (border ? 2 : 0)
    end

    def content_height : Int32
      height - (border ? 2 : 0)
    end
  end
end
