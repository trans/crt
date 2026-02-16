module CRT
  class Frame < Widget
    @children : Array(Widget)
    @direction : Direction
    @gap : Int32
    @title : String?
    @title_style : Ansi::Style
    @focused_child : Widget?
    @auto_width : Bool
    @auto_height : Bool

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   width : Int32? = nil, height : Int32? = nil,
                   style : Ansi::Style = Ansi::Style.default,
                   border : Ansi::Border? = nil,
                   shadow : Bool = false,
                   box : Ansi::Boxing? = nil,
                   @direction : Direction = Direction::Column,
                   @gap : Int32 = 0,
                   @title : String? = nil,
                   @title_style : Ansi::Style = Ansi::Style.default)
      @children = [] of Widget
      @focused_child = nil
      @auto_width = width.nil?
      @auto_height = height.nil?
      super(screen, x: x, y: y, width: width || 0, height: height || 0,
            style: style, border: border, shadow: shadow,
            focusable: true, box: box)
    end

    def children : Array(Widget)
      @children
    end

    def add(widget : Widget) : self
      @screen.unregister(widget)
      @children << widget unless @children.includes?(widget)
      layout!
      self
    end

    def <<(widget : Widget) : self
      add(widget)
    end

    def remove(widget : Widget) : self
      @children.delete(widget)
      if @focused_child == widget
        @focused_child.try(&.unfocus)
        @focused_child = nil
      end
      layout!
      self
    end

    def layout! : Nil
      offset = 0
      @children.each do |child|
        case @direction
        in .column?
          child.x = content_x
          child.y = content_y + offset
          offset += child.height + @gap
        in .row?
          child.x = content_x + offset
          child.y = content_y
          offset += child.width + @gap
        end
      end
      compute_frame_size if @auto_width || @auto_height
    end

    def draw(canvas : Ansi::Canvas) : Nil
      p = panel(canvas)
      p.fill(style).draw

      @children.each do |child|
        child.draw(canvas) if child.visible?
      end
    end

    def draw_overlay(canvas : Ansi::Canvas) : Nil
      if (t = @title) && border_size > 0
        canvas.write(content_x + 1, y, " #{t} ", @title_style)
      end
    end

    # Focus management

    def focus(direction : Int32 = 1) : Nil
      super
      focusable = @children.select { |c| c.focusable? && c.visible? }
      return if focusable.empty?
      fc = direction > 0 ? focusable.first : focusable.last
      focus_child(fc)
    end

    def unfocus : Nil
      super
      @focused_child.try(&.unfocus)
      @focused_child = nil
    end

    def focused_child : Widget?
      @focused_child
    end

    def handle_event(event : Ansi::Event) : Bool
      case event
      when Ansi::Key
        if event.code.tab?
          return cycle_child_focus(event.shift? ? -1 : 1)
        end
      end

      if fc = @focused_child
        fc.handle_event(event)
      else
        false
      end
    end

    def destroy : Nil
      @children.each(&.destroy)
      @children.clear
      super
    end

    private def focus_child(child : Widget) : Nil
      @focused_child.try(&.unfocus)
      @focused_child = child
      child.focus
    end

    private def cycle_child_focus(direction : Int32) : Bool
      focusable = @children.select { |c| c.focusable? && c.visible? }
      return false if focusable.empty?

      if current = @focused_child
        pos = focusable.index(current)
        if pos
          next_idx = pos + direction
          return false if next_idx < 0 || next_idx >= focusable.size
          focus_child(focusable[next_idx])
          return true
        end
      end

      target = direction > 0 ? focusable.first : focusable.last
      focus_child(target)
      true
    end

    private def first_focusable_child : Widget?
      @children.find { |c| c.focusable? && c.visible? }
    end

    private def compute_frame_size : Nil
      return if @children.empty?
      old_w, old_h = self.width, self.height
      inset = border_size * 2

      case @direction
      in .column?
        if @auto_width
          max_w = @children.max_of(&.width)
          self.width = max_w + inset
        end
        if @auto_height
          total_h = @children.sum(&.height) + @gap * (@children.size - 1)
          self.height = total_h + inset
        end
      in .row?
        if @auto_width
          total_w = @children.sum(&.width) + @gap * (@children.size - 1)
          self.width = total_w + inset
        end
        if @auto_height
          max_h = @children.max_of(&.height)
          self.height = max_h + inset
        end
      end

      if self.width != old_w || self.height != old_h
        reregister_boxing(self.x, self.y, old_w, old_h)
      end
    end
  end
end
