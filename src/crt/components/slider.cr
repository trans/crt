module CRT
  enum Orientation
    Vertical
    Horizontal
  end

  class Slider < Widget
    @orientation : Orientation
    @value : Float64
    @thumb_size : Float64
    @step : Float64
    @thumb_style : Ansi::Style
    @track_style : Ansi::Style
    @on_change : (Float64 -> Nil)?

    THUMB_DEFAULT = Ansi::Style.new(bg: Ansi::Color.indexed(15))
    THUMB_DIM     = Ansi::Style.new(bg: Ansi::Color.indexed(7))
    TRACK_DEFAULT = Ansi::Style.new(bg: Ansi::Color.indexed(8))

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   @orientation : Orientation = Orientation::Vertical,
                   length : Int32 = 10,
                   @value : Float64 = 0.0,
                   @thumb_size : Float64 = 0.0,
                   @step : Float64 = 0.1,
                   @thumb_style : Ansi::Style = THUMB_DEFAULT,
                   @track_style : Ansi::Style = TRACK_DEFAULT,
                   style : Ansi::Style = Ansi::Style.default,
                   &on_change : Float64 ->)
      @on_change = on_change
      @value = @value.clamp(0.0, 1.0)
      @thumb_size = @thumb_size.clamp(0.0, 1.0)
      w = @orientation.vertical? ? 1 : length
      h = @orientation.vertical? ? length : 1
      super(screen, x: x, y: y, width: w, height: h,
            style: style, focusable: true)
    end

    def initialize(screen : Screen, *, x : Int32, y : Int32,
                   @orientation : Orientation = Orientation::Vertical,
                   length : Int32 = 10,
                   @value : Float64 = 0.0,
                   @thumb_size : Float64 = 0.0,
                   @step : Float64 = 0.1,
                   @thumb_style : Ansi::Style = THUMB_DEFAULT,
                   @track_style : Ansi::Style = TRACK_DEFAULT,
                   style : Ansi::Style = Ansi::Style.default)
      @on_change = nil
      @value = @value.clamp(0.0, 1.0)
      @thumb_size = @thumb_size.clamp(0.0, 1.0)
      w = @orientation.vertical? ? 1 : length
      h = @orientation.vertical? ? length : 1
      super(screen, x: x, y: y, width: w, height: h,
            style: style, focusable: true)
    end

    getter orientation : Orientation
    getter value : Float64
    getter thumb_size : Float64
    getter step : Float64

    def value=(v : Float64) : Nil
      @value = v.clamp(0.0, 1.0)
    end

    def thumb_size=(v : Float64) : Nil
      @thumb_size = v.clamp(0.0, 1.0)
    end

    property on_change : (Float64 -> Nil)?

    def draw(canvas : Ansi::Canvas) : Nil
      track_len = @orientation.vertical? ? height : width
      half_cells = track_len * 2

      thumb_h = @thumb_size > 0.0 ? {(@thumb_size * half_cells).round.to_i, 2}.max : 2
      max_pos = {half_cells - thumb_h, 0}.max
      thumb_pos = (@value * max_pos).round.to_i

      thumb_bg = focused? ? @thumb_style.bg : THUMB_DIM.bg
      track_bg = @track_style.bg
      full_thumb_s = Ansi::Style.new(bg: thumb_bg)
      full_track_s = Ansi::Style.new(bg: track_bg)
      half_s = Ansi::Style.new(fg: thumb_bg, bg: track_bg)

      if @orientation.vertical?
        height.times do |row|
          top = row * 2
          bot = row * 2 + 1
          in_top = top >= thumb_pos && top < thumb_pos + thumb_h
          in_bot = bot >= thumb_pos && bot < thumb_pos + thumb_h
          if in_top && in_bot
            canvas.put(x, y + row, " ", full_thumb_s)
          elsif in_top
            canvas.put(x, y + row, "▀", half_s)
          elsif in_bot
            canvas.put(x, y + row, "▄", half_s)
          else
            canvas.put(x, y + row, " ", full_track_s)
          end
        end
      else
        width.times do |col|
          left = col * 2
          right = col * 2 + 1
          in_left = left >= thumb_pos && left < thumb_pos + thumb_h
          in_right = right >= thumb_pos && right < thumb_pos + thumb_h
          if in_left && in_right
            canvas.put(x + col, y, " ", full_thumb_s)
          elsif in_left
            canvas.put(x + col, y, "▌", half_s)
          elsif in_right
            canvas.put(x + col, y, "▐", half_s)
          else
            canvas.put(x + col, y, " ", full_track_s)
          end
        end
      end
    end

    def handle_event(event : Ansi::Event) : Bool
      case event
      when Ansi::Key
        if event.code.up? || event.code.left?
          change(-@step)
          return true
        elsif event.code.down? || event.code.right?
          change(@step)
          return true
        elsif event.code.home?
          set_value(0.0)
          return true
        elsif event.code.end?
          set_value(1.0)
          return true
        elsif event.code.page_up?
          change(-@step * 5)
          return true
        elsif event.code.page_down?
          change(@step * 5)
          return true
        end
      when Ansi::Mouse
        if event.button.left? && event.action.press? && hit?(event.x, event.y)
          track_len = @orientation.vertical? ? height : width
          pos = @orientation.vertical? ? (event.y - y) : (event.x - x)
          set_value(track_len > 1 ? pos.to_f / (track_len - 1).to_f : 0.0)
          return true
        end
      end
      false
    end

    private def change(delta : Float64) : Nil
      set_value(@value + delta)
    end

    private def set_value(v : Float64) : Nil
      old = @value
      @value = v.clamp(0.0, 1.0)
      @on_change.try(&.call(@value)) if @value != old
    end
  end
end
