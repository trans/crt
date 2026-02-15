module CRT
  class Screen
    getter ansi : Ansi::Screen
    getter widgets : Array(Widget)
    @focused : Widget?
    property modal : Widget?

    def initialize(io : IO = STDOUT, **opts)
      @ansi = Ansi::Screen.new(io, **opts)
      @widgets = [] of Widget
      @focused = nil
      @modal = nil
    end

    def self.open(io : IO = STDOUT, **opts, &) : Nil
      screen = new(io, **opts)
      screen.start
      begin
        yield screen
      ensure
        screen.stop
      end
    end

    def start : Nil
      @ansi.start
    end

    def stop : Nil
      @ansi.stop
    end

    def quit : Nil
      stop
    end

    def run(*, fps : Int32 = 30, &) : Nil
      interval = Time::Span.new(nanoseconds: (1_000_000_000 // fps).to_i64)
      while @ansi.running?
        yield
        draw
        @ansi.present
        sleep interval
      end
    end

    def draw : Nil
      @ansi.clear
      @widgets.each do |widget|
        widget.draw(@ansi.render) if widget.visible?
      end
    end

    # Widget management

    def register(widget : Widget) : Nil
      @widgets << widget unless @widgets.includes?(widget)
    end

    def unregister(widget : Widget) : Nil
      @modal = nil if @modal == widget
      @widgets.delete(widget)
      if @focused == widget
        widget.unfocus
        @focused = nil
      end
    end

    def raise(widget : Widget) : Nil
      if @widgets.delete(widget)
        @widgets << widget
      end
    end

    def lower(widget : Widget) : Nil
      if @widgets.delete(widget)
        @widgets.unshift(widget)
      end
    end

    # Focus management

    def focused_widget : Widget?
      @focused
    end

    def focus(widget : Widget) : Nil
      return unless @widgets.includes?(widget)
      return unless widget.focusable? && widget.visible?
      @focused.try(&.unfocus)
      @focused = widget
      widget.focus
    end

    def focus_next : Nil
      cycle_focus(1)
    end

    def focus_prev : Nil
      cycle_focus(-1)
    end

    # Input dispatch

    def dispatch(event : Ansi::Event) : Bool
      if m = @modal
        return m.handle_event(event)
      end

      case event
      when Ansi::Key
        if event.code.tab?
          if event.shift?
            focus_prev
          else
            focus_next
          end
          return true
        end
      end

      if fw = focused_widget
        fw.handle_event(event)
      else
        false
      end
    end

    # Delegated from Ansi::Screen

    def width : Int32
      @ansi.width
    end

    def height : Int32
      @ansi.height
    end

    def poll_event : Ansi::Event?
      @ansi.poll_event
    end

    def read_event : Ansi::Event?
      @ansi.read_event
    end

    def read_key : Ansi::Key?
      @ansi.read_key
    end

    # Positioning helpers

    def center_x(w : Int32) : Int32
      (width - w) // 2
    end

    def center_y(h : Int32) : Int32
      (height - h) // 2
    end

    private def cycle_focus(direction : Int32) : Nil
      focusable = @widgets.select { |w| w.focusable? && w.visible? }
      return if focusable.empty?

      if current = @focused
        pos = focusable.index(current)
        if pos
          target_idx = (pos + direction) % focusable.size
        else
          target_idx = direction > 0 ? 0 : focusable.size - 1
        end
      else
        target_idx = direction > 0 ? 0 : focusable.size - 1
      end

      focus(focusable[target_idx])
    end
  end
end
