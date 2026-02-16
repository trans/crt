require "../spec_helper"

describe CRT::Build do
  describe "CRT.build" do
    it "returns a Build instance" do
      screen = test_screen
      ui = CRT.build(screen) { }
      ui.should be_a(CRT::Build)
    end
  end

  describe "ID access" do
    it "stores widgets by id" do
      screen = test_screen
      ui = CRT.build(screen) do
        label "Hello", id: :greeting, x: 0, y: 0
      end
      ui[:greeting].should be_a(CRT::Label)
    end

    it "[]? returns nil for unknown id" do
      screen = test_screen
      ui = CRT.build(screen) { }
      ui[:missing]?.should be_nil
    end

    it "[] raises for unknown id" do
      screen = test_screen
      ui = CRT.build(screen) { }
      expect_raises(KeyError) { ui[:missing] }
    end

    it "widgets without id are not stored" do
      screen = test_screen
      ui = CRT.build(screen) do
        label "No ID", x: 0, y: 0
      end
      ui[:anything]?.should be_nil
    end
  end

  describe "leaf widgets" do
    it "creates a Label" do
      screen = test_screen
      ui = CRT.build(screen) do
        label "Test", id: :lbl, x: 5, y: 3
      end
      lbl = ui[:lbl].as(CRT::Label)
      lbl.x.should eq(5)
      lbl.y.should eq(3)
    end

    it "creates a Button with action" do
      screen = test_screen
      fired = false
      ui = CRT.build(screen) do
        button id: :btn, text: "Go", x: 0, y: 0 { fired = true }
      end
      btn = ui[:btn].as(CRT::Button)
      btn.text.should eq("Go")
    end

    it "creates a Button without action" do
      screen = test_screen
      ui = CRT.build(screen) do
        button id: :btn, text: "Go", x: 0, y: 0
      end
      ui[:btn].should be_a(CRT::Button)
    end

    it "creates an Entry with callback" do
      screen = test_screen
      ui = CRT.build(screen) do
        entry id: :name, width: 20, x: 0, y: 0 { |_| }
      end
      ui[:name].should be_a(CRT::Entry)
    end

    it "creates an Entry without callback" do
      screen = test_screen
      ui = CRT.build(screen) do
        entry id: :name, width: 20, x: 0, y: 0
      end
      ui[:name].should be_a(CRT::Entry)
    end

    it "creates an EntryBox" do
      screen = test_screen
      ui = CRT.build(screen) do
        entry_box id: :notes, width: 30, height: 5, x: 0, y: 0
      end
      ui[:notes].should be_a(CRT::EntryBox)
    end

    it "creates a Checkbox with callback" do
      screen = test_screen
      ui = CRT.build(screen) do
        checkbox "Agree", id: :agree, x: 0, y: 0 { |_| }
      end
      ui[:agree].should be_a(CRT::Checkbox)
    end

    it "creates a Checkbox without callback" do
      screen = test_screen
      ui = CRT.build(screen) do
        checkbox "Agree", id: :agree, x: 0, y: 0
      end
      ui[:agree].should be_a(CRT::Checkbox)
    end

    it "creates a RadioGroup with callback" do
      screen = test_screen
      ui = CRT.build(screen) do
        radio_group id: :color, items: ["R", "G", "B"], x: 0, y: 0 { |_| }
      end
      ui[:color].should be_a(CRT::RadioGroup)
    end

    it "creates a RadioGroup without callback" do
      screen = test_screen
      ui = CRT.build(screen) do
        radio_group id: :color, items: ["R", "G", "B"], x: 0, y: 0
      end
      ui[:color].should be_a(CRT::RadioGroup)
    end

    it "creates a ListBox with callback" do
      screen = test_screen
      ui = CRT.build(screen) do
        list_box id: :files, items: ["a.cr", "b.cr"], x: 0, y: 0 { |_| }
      end
      ui[:files].should be_a(CRT::ListBox)
    end

    it "creates a ListBox without callback" do
      screen = test_screen
      ui = CRT.build(screen) do
        list_box id: :files, items: ["a.cr", "b.cr"], x: 0, y: 0
      end
      ui[:files].should be_a(CRT::ListBox)
    end

    it "creates an ItemList" do
      screen = test_screen
      ui = CRT.build(screen) do
        item_list id: :pick, items: ["X", "Y"], x: 0, y: 0
      end
      ui[:pick].should be_a(CRT::ItemList)
    end

    it "creates a Slider" do
      screen = test_screen
      ui = CRT.build(screen) do
        slider id: :vol, x: 0, y: 0, length: 10
      end
      ui[:vol].should be_a(CRT::Slider)
    end

    it "creates a ProgressBar" do
      screen = test_screen
      ui = CRT.build(screen) do
        progress_bar id: :prog, x: 0, y: 0, width: 20
      end
      ui[:prog].should be_a(CRT::ProgressBar)
    end

    it "creates a TextBox" do
      screen = test_screen
      ui = CRT.build(screen) do
        text_box id: :info, x: 0, y: 0, width: 30, height: 10, text: "Hello"
      end
      ui[:info].should be_a(CRT::TextBox)
    end
  end

  describe "containers" do
    it "creates a Frame with children" do
      screen = test_screen
      ui = CRT.build(screen) do
        frame id: :frm, x: 0, y: 0, width: 40, height: 20 do
          label "Inside", id: :inner
        end
      end
      frm = ui[:frm].as(CRT::Frame)
      frm.children.size.should eq(1)
      ui[:inner].should be_a(CRT::Label)
    end

    it "children auto-add to frame context" do
      screen = test_screen
      ui = CRT.build(screen) do
        frame id: :frm, x: 0, y: 0, width: 40, height: 20 do
          label "A", id: :a
          label "B", id: :b
        end
      end
      frm = ui[:frm].as(CRT::Frame)
      frm.children.size.should eq(2)
    end

    it "nested frames work" do
      screen = test_screen
      ui = CRT.build(screen) do
        frame id: :outer, x: 0, y: 0, width: 60, height: 30 do
          frame id: :inner, width: 40, height: 20 do
            label "Deep", id: :lbl
          end
        end
      end
      outer = ui[:outer].as(CRT::Frame)
      inner = ui[:inner].as(CRT::Frame)
      outer.children.size.should eq(1)
      inner.children.size.should eq(1)
    end

    it "top-level widgets are not added to any container" do
      screen = test_screen
      ui = CRT.build(screen) do
        label "Standalone", id: :s, x: 0, y: 0
        frame id: :frm, x: 0, y: 5, width: 40, height: 10 do
          label "Child", id: :c
        end
      end
      frm = ui[:frm].as(CRT::Frame)
      frm.children.size.should eq(1) # only :c, not :s
    end
  end

  describe "tabs" do
    it "creates Tabs with pages" do
      screen = test_screen
      ui = CRT.build(screen) do
        tabs id: :t, x: 0, y: 0, width: 40, height: 20 do
          page "First" do
            label "Page 1", id: :p1
          end
          page "Second" do
            label "Page 2", id: :p2
          end
        end
      end
      t = ui[:t].as(CRT::Tabs)
      t.pages.size.should eq(2)
      ui[:p1].should be_a(CRT::Label)
      ui[:p2].should be_a(CRT::Label)
    end

    it "page raises outside tabs" do
      screen = test_screen
      expect_raises(Exception, "page must be inside a tabs block") do
        CRT.build(screen) do
          page "Bad" do
          end
        end
      end
    end

    it "widgets in page add to page frame" do
      screen = test_screen
      ui = CRT.build(screen) do
        tabs id: :t, x: 0, y: 0, width: 50, height: 20 do
          page "Settings" do
            checkbox "Enable", id: :cb
            entry id: :val, width: 20
          end
        end
      end
      t = ui[:t].as(CRT::Tabs)
      frame = t.pages[0].frame
      frame.children.size.should eq(2)
    end
  end

  describe "dialog" do
    it "creates a Dialog" do
      screen = test_screen
      ui = CRT.build(screen) do
        dialog id: :dlg, message: "Sure?", buttons: ["Yes", "No"] { |_| }
      end
      ui[:dlg].should be_a(CRT::Dialog)
    end

    it "dialog without callback" do
      screen = test_screen
      ui = CRT.build(screen) do
        dialog id: :dlg, message: "Info"
      end
      ui[:dlg].should be_a(CRT::Dialog)
    end

    it "dialog is not added to container context" do
      screen = test_screen
      ui = CRT.build(screen) do
        frame id: :frm, x: 0, y: 0, width: 40, height: 20 do
          label "A", id: :a
          dialog id: :dlg, message: "Popup"
        end
      end
      frm = ui[:frm].as(CRT::Frame)
      frm.children.size.should eq(1) # only the label
    end
  end

  describe "mixed building" do
    it "builds a complex UI" do
      screen = test_screen
      ui = CRT.build(screen) do
        tabs id: :main, x: 2, y: 1, width: 50, height: 18 do
          page "Profile" do
            label "Name"
            entry id: :name, width: 46
          end
          page "Settings" do
            checkbox "Dark mode", id: :dark
            radio_group id: :theme, items: ["Blue", "Green", "Red"]
          end
        end
        button id: :save, x: 2, y: 20, text: "Save" { }
      end

      ui[:main].should be_a(CRT::Tabs)
      ui[:name].should be_a(CRT::Entry)
      ui[:dark].should be_a(CRT::Checkbox)
      ui[:theme].should be_a(CRT::RadioGroup)
      ui[:save].should be_a(CRT::Button)

      t = ui[:main].as(CRT::Tabs)
      t.pages.size.should eq(2)
    end
  end
end
