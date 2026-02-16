module CRT
  # Declarative DSL for building widget trees. Uses `with ... yield` so
  # widget methods can be called without a receiver inside the block.
  #
  #   ui = CRT.build(screen) do
  #     tabs id: :main, x: 2, y: 1, width: 50, height: 18 do
  #       page "Profile" do
  #         label "Name"
  #         entry id: :name, width: 46
  #       end
  #     end
  #     button id: :toggle, x: 2, y: 20, text: "Go"
  #   end
  #
  #   ui[:name].as(CRT::Entry).text  # => ""
  #
  # TODO: Explore macro-based DSL that could generate typed accessors
  # (e.g. `ui.name : Entry`) to avoid `.as()` casts on lookup.
  #
  # Widgets inside a container (page, frame) get added to that container
  # automatically — no explicit x/y needed. Top-level widgets need
  # coordinates.
  #
  # Only widgets given an `id:` are stored; access them via `ui[:id]`.
  def self.build(screen : Screen, &) : Build
    builder = Build.new(screen)
    with builder yield
    builder
  end

  class Build
    @screen : Screen
    @context : Array(Frame | Tabs)
    @widgets : Hash(Symbol, Widget)

    def initialize(@screen : Screen)
      @context = [] of (Frame | Tabs)
      @widgets = {} of Symbol => Widget
    end

    def [](id : Symbol) : Widget
      @widgets[id]
    end

    def []?(id : Symbol) : Widget?
      @widgets[id]?
    end

    # --- Containers ---

    def tabs(*, id : Symbol? = nil, x : Int32 = 0, y : Int32 = 0,
             width : Int32, height : Int32,
             style : Ansi::Style = CRT.theme.base,
             border : Ansi::Border? = nil,
             decor : Decor = Decor::None,
             box : Ansi::Boxing? = nil,
             separator : Bool = false,
             tab_type : TabType = TabType::Folder, &) : Tabs
      w = Tabs.new(@screen, x: x, y: y, width: width, height: height,
                   style: style, border: border, decor: decor, box: box,
                   separator: separator, tab_type: tab_type)
      register(w, id)
      @context.push(w)
      with self yield
      @context.pop
      w
    end

    def page(label : String, &) : Frame
      ctx = @context.last?
      unless ctx.is_a?(Tabs)
        raise "page must be inside a tabs block"
      end
      frame = ctx.add(label)
      @context.push(frame)
      with self yield
      @context.pop
      frame
    end

    def frame(*, id : Symbol? = nil, x : Int32 = 0, y : Int32 = 0,
              width : Int32? = nil, height : Int32? = nil,
              style : Ansi::Style = CRT.theme.base,
              border : Ansi::Border? = nil,
              decor : Decor = Decor::None,
              box : Ansi::Boxing? = nil,
              direction : Direction = Direction::Column,
              gap : Int32 = 0,
              title : String? = nil, &) : Frame
      w = Frame.new(@screen, x: x, y: y, width: width, height: height,
                    style: style, border: border, decor: decor, box: box,
                    direction: direction, gap: gap, title: title)
      register(w, id)
      @context.push(w)
      with self yield
      @context.pop
      w
    end

    # --- Leaf widgets ---

    def label(text : String = "", *, id : Symbol? = nil,
              x : Int32 = 0, y : Int32 = 0,
              width : Int32? = nil, height : Int32? = nil,
              style : Ansi::Style = CRT.theme.base,
              border : Ansi::Border? = nil,
              decor : Decor = Decor::None,
              align : Ansi::Align = Ansi::Align::Left,
              wrap : Ansi::Wrap = Ansi::Wrap::None,
              pad : Int32 = 0) : Label
      w = Label.new(@screen, x: x, y: y, text: text,
                    width: width, height: height,
                    style: style, border: border, decor: decor,
                    align: align, wrap: wrap, pad: pad)
      register(w, id)
      w
    end

    def button(*, id : Symbol? = nil, text : String,
               x : Int32 = 0, y : Int32 = 0,
               width : Int32? = nil, height : Int32? = nil,
               style : Ansi::Style = CRT.theme.field,
               border : Ansi::Border? = nil,
               decor : Decor = Decor::None,
               pad : Int32 = 2, &action : -> Nil) : Button
      w = Button.new(@screen, x: x, y: y, text: text,
                     width: width, height: height,
                     style: style, border: border, decor: decor,
                     pad: pad, &action)
      register(w, id)
      w
    end

    def button(*, id : Symbol? = nil, text : String,
               x : Int32 = 0, y : Int32 = 0,
               width : Int32? = nil, height : Int32? = nil,
               style : Ansi::Style = CRT.theme.field,
               border : Ansi::Border? = nil,
               decor : Decor = Decor::None,
               pad : Int32 = 2) : Button
      w = Button.new(@screen, x: x, y: y, text: text,
                     width: width, height: height,
                     style: style, border: border, decor: decor,
                     pad: pad)
      register(w, id)
      w
    end

    def entry(*, id : Symbol? = nil, width : Int32,
              x : Int32 = 0, y : Int32 = 0,
              text : String = "",
              style : Ansi::Style = CRT.theme.field,
              border : Ansi::Border? = Ansi::Border::Single,
              decor : Decor = Decor::None,
              pad : Int32 = 1, &on_submit : String ->) : Entry
      w = Entry.new(@screen, x: x, y: y, width: width, text: text,
                    style: style, border: border, decor: decor,
                    pad: pad, &on_submit)
      register(w, id)
      w
    end

    def entry(*, id : Symbol? = nil, width : Int32,
              x : Int32 = 0, y : Int32 = 0,
              text : String = "",
              style : Ansi::Style = CRT.theme.field,
              border : Ansi::Border? = Ansi::Border::Single,
              decor : Decor = Decor::None,
              pad : Int32 = 1) : Entry
      w = Entry.new(@screen, x: x, y: y, width: width, text: text,
                    style: style, border: border, decor: decor,
                    pad: pad)
      register(w, id)
      w
    end

    def entry_box(*, id : Symbol? = nil,
                  x : Int32 = 0, y : Int32 = 0,
                  width : Int32, height : Int32,
                  text : String = "",
                  style : Ansi::Style = CRT.theme.field,
                  border : Ansi::Border? = nil,
                  decor : Decor = Decor::None,
                  scrollbar : Bool = false) : EntryBox
      w = EntryBox.new(@screen, x: x, y: y, width: width, height: height,
                       text: text, style: style, border: border, decor: decor,
                       scrollbar: scrollbar)
      register(w, id)
      w
    end

    def checkbox(text : String = "", *, id : Symbol? = nil,
                 x : Int32 = 0, y : Int32 = 0,
                 width : Int32? = nil, height : Int32? = nil,
                 checked : Bool = false,
                 style : Ansi::Style = CRT.theme.base,
                 border : Ansi::Border? = nil,
                 decor : Decor = Decor::None,
                 &on_change : Bool ->) : Checkbox
      w = Checkbox.new(@screen, x: x, y: y, text: text,
                       checked: checked, width: width, height: height,
                       style: style, border: border, decor: decor,
                       &on_change)
      register(w, id)
      w
    end

    def checkbox(text : String = "", *, id : Symbol? = nil,
                 x : Int32 = 0, y : Int32 = 0,
                 width : Int32? = nil, height : Int32? = nil,
                 checked : Bool = false,
                 style : Ansi::Style = CRT.theme.base,
                 border : Ansi::Border? = nil,
                 decor : Decor = Decor::None) : Checkbox
      w = Checkbox.new(@screen, x: x, y: y, text: text,
                       checked: checked, width: width, height: height,
                       style: style, border: border, decor: decor)
      register(w, id)
      w
    end

    def radio_group(*, id : Symbol? = nil,
                    items : Array(String),
                    x : Int32 = 0, y : Int32 = 0,
                    width : Int32? = nil, height : Int32? = nil,
                    selected : Int32 = 0,
                    style : Ansi::Style = CRT.theme.base,
                    border : Ansi::Border? = nil,
                    decor : Decor = Decor::None,
                    &on_change : Int32 ->) : RadioGroup
      w = RadioGroup.new(@screen, x: x, y: y, items: items,
                         selected: selected, width: width, height: height,
                         style: style, border: border, decor: decor,
                         &on_change)
      register(w, id)
      w
    end

    def radio_group(*, id : Symbol? = nil,
                    items : Array(String),
                    x : Int32 = 0, y : Int32 = 0,
                    width : Int32? = nil, height : Int32? = nil,
                    selected : Int32 = 0,
                    style : Ansi::Style = CRT.theme.base,
                    border : Ansi::Border? = nil,
                    decor : Decor = Decor::None) : RadioGroup
      w = RadioGroup.new(@screen, x: x, y: y, items: items,
                         selected: selected, width: width, height: height,
                         style: style, border: border, decor: decor)
      register(w, id)
      w
    end

    def list_box(*, id : Symbol? = nil,
                 items : Array(String),
                 x : Int32 = 0, y : Int32 = 0,
                 width : Int32? = nil, height : Int32? = nil,
                 selected : Int32 = 0,
                 style : Ansi::Style = CRT.theme.base,
                 border : Ansi::Border? = Ansi::Border::Single,
                 decor : Decor = Decor::None,
                 &on_change : Int32 ->) : ListBox
      w = ListBox.new(@screen, x: x, y: y, items: items,
                      selected: selected, width: width, height: height,
                      style: style, border: border, decor: decor,
                      &on_change)
      register(w, id)
      w
    end

    def list_box(*, id : Symbol? = nil,
                 items : Array(String),
                 x : Int32 = 0, y : Int32 = 0,
                 width : Int32? = nil, height : Int32? = nil,
                 selected : Int32 = 0,
                 style : Ansi::Style = CRT.theme.base,
                 border : Ansi::Border? = Ansi::Border::Single,
                 decor : Decor = Decor::None) : ListBox
      w = ListBox.new(@screen, x: x, y: y, items: items,
                      selected: selected, width: width, height: height,
                      style: style, border: border, decor: decor)
      register(w, id)
      w
    end

    def item_list(*, id : Symbol? = nil,
                  items : Array(String),
                  x : Int32 = 0, y : Int32 = 0,
                  width : Int32? = nil, height : Int32? = nil,
                  selected : Int32 = 0,
                  style : Ansi::Style = CRT.theme.base,
                  border : Ansi::Border? = nil,
                  decor : Decor = Decor::None) : ItemList
      w = ItemList.new(@screen, x: x, y: y, items: items,
                       selected: selected, width: width, height: height,
                       style: style, border: border, decor: decor)
      register(w, id)
      w
    end

    def slider(*, id : Symbol? = nil,
               x : Int32 = 0, y : Int32 = 0,
               orientation : Orientation = Orientation::Vertical,
               length : Int32 = 10,
               value : Float64 = 0.0,
               step : Float64 = 0.1,
               style : Ansi::Style = CRT.theme.base) : Slider
      w = Slider.new(@screen, x: x, y: y,
                     orientation: orientation, length: length,
                     value: value, step: step, style: style)
      register(w, id)
      w
    end

    def progress_bar(*, id : Symbol? = nil,
                     x : Int32 = 0, y : Int32 = 0,
                     width : Int32,
                     value : Float64 = 0.0,
                     style : Ansi::Style = CRT.theme.base,
                     border : Ansi::Border? = nil,
                     decor : Decor = Decor::None) : ProgressBar
      w = ProgressBar.new(@screen, x: x, y: y, width: width,
                          value: value, style: style,
                          border: border, decor: decor)
      register(w, id)
      w
    end

    def text_box(*, id : Symbol? = nil,
                 x : Int32 = 0, y : Int32 = 0,
                 width : Int32, height : Int32,
                 text : String = "",
                 wrap : Ansi::Wrap = Ansi::Wrap::Word,
                 scrollbar : Bool = false,
                 style : Ansi::Style = CRT.theme.base,
                 border : Ansi::Border? = nil,
                 decor : Decor = Decor::None) : TextBox
      w = TextBox.new(@screen, x: x, y: y, width: width, height: height,
                      text: text, wrap: wrap, scrollbar: scrollbar,
                      style: style, border: border, decor: decor)
      register(w, id)
      w
    end

    def dialog(*, id : Symbol? = nil,
               title : String? = nil,
               message : String,
               buttons : Array(String) = ["OK"],
               style : Ansi::Style = CRT.theme.base,
               border : Ansi::Border = Ansi::Border::Rounded,
               decor : Decor = Decor::Shadow,
               &on_choice : Int32 ->) : Dialog
      w = Dialog.new(@screen, title: title, message: message,
                     buttons: buttons, style: style,
                     border: border, decor: decor, &on_choice)
      store(w, id)
      w
    end

    def dialog(*, id : Symbol? = nil,
               title : String? = nil,
               message : String,
               buttons : Array(String) = ["OK"],
               style : Ansi::Style = CRT.theme.base,
               border : Ansi::Border = Ansi::Border::Rounded,
               decor : Decor = Decor::Shadow) : Dialog
      w = Dialog.new(@screen, title: title, message: message,
                     buttons: buttons, style: style,
                     border: border, decor: decor)
      store(w, id)
      w
    end

    # --- Internals ---

    private def register(widget : Widget, id : Symbol?) : Nil
      add_to_context(widget)
      @widgets[id] = widget if id
    end

    private def store(widget : Widget, id : Symbol?) : Nil
      @widgets[id] = widget if id
    end

    private def add_to_context(widget : Widget) : Nil
      if ctx = @context.last?
        case ctx
        when Frame
          ctx << widget
        end
      end
    end
  end
end
