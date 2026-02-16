module CRT
  # TODO: Compose real child widgets (Label + Buttons) instead of drawing
  # everything manually. Requires solving modal event routing to children —
  # currently @screen.modal sends all events to Dialog, bypassing child widgets.
  class Dialog < Widget
    PAD        = 2
    BUTTON_PAD = 2
    BUTTON_GAP = 2

    @title : String?
    @message_lines : Array(String)
    @buttons : Array(String)
    @selected : Int32
    @on_choice : (Int32 -> Nil)?

    def initialize(screen : Screen, *,
                   @title : String? = nil,
                   message : String,
                   @buttons : Array(String) = ["OK"],
                   style : Ansi::Style = CRT.theme.base,
                   border : Ansi::Border = Ansi::Border::Rounded,
                   decor : Decor = Decor::Shadow,
                   theme : Theme = CRT.theme,
                   &on_choice : Int32 ->)
      @on_choice = on_choice
      @selected = 0
      @message_lines = message.split('\n')
      w, h = compute_size(border)
      cx = screen.center_x(w + (decor.none? ? 0 : 1))
      cy = screen.center_y(h + (decor.none? ? 0 : 1))
      super(screen, x: cx, y: cy, width: w, height: h,
            style: style, border: border, decor: decor, focusable: true,
            theme: theme)
      @screen.raise(self)
      @screen.focus(self)
      @screen.modal = self
    end

    def initialize(screen : Screen, *,
                   @title : String? = nil,
                   message : String,
                   @buttons : Array(String) = ["OK"],
                   style : Ansi::Style = CRT.theme.base,
                   border : Ansi::Border = Ansi::Border::Rounded,
                   decor : Decor = Decor::Shadow,
                   theme : Theme = CRT.theme)
      @on_choice = nil
      @selected = 0
      @message_lines = message.split('\n')
      w, h = compute_size(border)
      cx = screen.center_x(w + (decor.none? ? 0 : 1))
      cy = screen.center_y(h + (decor.none? ? 0 : 1))
      super(screen, x: cx, y: cy, width: w, height: h,
            style: style, border: border, decor: decor, focusable: true,
            theme: theme)
      @screen.raise(self)
      @screen.focus(self)
      @screen.modal = self
    end

    getter selected : Int32
    getter buttons : Array(String)

    def draw(canvas : Ansi::Canvas) : Nil
      p = panel(canvas).fill(style)
      case decor
      when .shadow? then p = p.shadow
      when .bevel?  then p = p.bevel
      else               # none
      end
      p.draw

      # Title on border row
      if t = @title
        title_str = " #{t} "
        tw = Ansi::DisplayWidth.width(title_str)
        title_x = x + 1 + (width - 2 - tw) // 2
        canvas.write(title_x, y, title_str, style)
      end

      # Message lines
      @message_lines.each_with_index do |line, i|
        canvas.write(content_x + PAD, content_y + 1 + i, line, style)
      end

      # Buttons centered on bottom row
      button_y = content_y + content_height - 2
      total_w = buttons_row_width
      start_x = content_x + (content_width - total_w) // 2

      bx = start_x
      @buttons.each_with_index do |label, i|
        btn_text = " " * BUTTON_PAD + label + " " * BUTTON_PAD
        btn_w = Ansi::DisplayWidth.width(btn_text)
        btn_style = theme.resolve(style, focused: i == @selected)
        canvas.write(bx, button_y, btn_text, btn_style)
        bx += btn_w + BUTTON_GAP
      end
    end

    def handle_event(event : Ansi::Event) : Bool
      case event
      when Ansi::Key
        if event.code.tab? && event.shift? || event.code.left?
          @selected = (@selected - 1) % @buttons.size
        elsif event.code.tab? || event.code.right?
          @selected = (@selected + 1) % @buttons.size
        elsif event.code.enter? || (event.code.char? && event.char == " ")
          dismiss(@selected)
        elsif event.code.escape?
          dismiss(0)
        end
      when Ansi::Mouse
        if event.button.left? && event.action.press? && hit?(event.x, event.y)
          if btn = button_at(event.x, event.y)
            dismiss(btn)
          end
        end
      end
      true # consume all events while modal
    end

    private def dismiss(choice : Int32) : Nil
      @screen.modal = nil
      cb = @on_choice
      destroy
      cb.try(&.call(choice))
    end

    private def compute_size(border : Ansi::Border?) : {Int32, Int32}
      inset = border ? 2 : 0

      # Title width
      title_w = if t = @title
                  Ansi::DisplayWidth.width(t) + 4 # " title " + border chars
                else
                  0
                end

      # Message width
      msg_w = Ansi::DisplayWidth.max_width(@message_lines) + PAD * 2

      # Buttons width
      btn_w = buttons_row_width + PAD * 2

      content_w = {title_w, msg_w, btn_w}.max
      w = content_w + inset

      # Height: top_pad + message + gap + buttons + bottom_pad
      content_h = 1 + @message_lines.size + 1 + 1 + 1
      h = content_h + inset

      {w, h}
    end

    private def buttons_row_width : Int32
      @buttons.sum { |b| Ansi::DisplayWidth.width(b) + BUTTON_PAD * 2 } +
        BUTTON_GAP * ({@buttons.size - 1, 0}.max)
    end

    private def button_at(mx : Int32, my : Int32) : Int32?
      button_y = content_y + content_height - 2
      return nil unless my == button_y

      total_w = buttons_row_width
      start_x = content_x + (content_width - total_w) // 2

      bx = start_x
      @buttons.each_with_index do |label, i|
        btn_w = Ansi::DisplayWidth.width(label) + BUTTON_PAD * 2
        if mx >= bx && mx < bx + btn_w
          return i
        end
        bx += btn_w + BUTTON_GAP
      end
      nil
    end
  end
end
