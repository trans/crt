module CRT
  class Label < Widget
    @text : String | Ansi::Style::Text
    @text_style : Ansi::Style
    @align : Ansi::Align
    @valign : Ansi::VAlign
    @wrap : Ansi::Wrap
    @pad : Int32
    @fill : Ansi::Style | Ansi::Style::Char | Nil

    def initialize(screen : Screen, *, @x : Int32, @y : Int32,
                   width : Int32? = nil, height : Int32? = nil,
                   @text : String | Ansi::Style::Text = "",
                   @text_style : Ansi::Style = Ansi::Style.default,
                   style : Ansi::Style = Ansi::Style.default,
                   border : Ansi::Border? = nil,
                   shadow : Bool = false,
                   @align : Ansi::Align = Ansi::Align::Left,
                   @valign : Ansi::VAlign = Ansi::VAlign::Top,
                   @wrap : Ansi::Wrap = Ansi::Wrap::None,
                   @pad : Int32 = 0,
                   @fill : Ansi::Style | Ansi::Style::Char | Nil = nil)
      w, h = compute_size(@text, border, @pad)
      super(screen, x: @x, y: @y, width: width || w, height: height || h,
            style: style, border: border, shadow: shadow)
    end

    def text : String | Ansi::Style::Text
      @text
    end

    def text=(value : String | Ansi::Style::Text) : Nil
      @text = value
    end

    def draw(canvas : Ansi::Canvas) : Nil
      p = panel(canvas)
      if f = @fill
        p = p.fill(f)
      end
      p.text(@text, style: @text_style, align: @align, valign: @valign,
             wrap: @wrap, pad: @pad).draw
    end

    private def compute_size(text : String | Ansi::Style::Text,
                             border : Ansi::Border?, pad : Int32) : {Int32, Int32}
      str = case text
            in String           then text
            in Ansi::Style::Text then text.to_s
            end
      lines = str.split('\n')
      inset = border ? 2 : 0
      padding = pad * 2
      content_w = Ansi::DisplayWidth.max_width(lines)
      content_h = lines.size
      {content_w + inset + padding, content_h + inset}
    end
  end
end
