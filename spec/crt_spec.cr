require "./spec_helper"

describe CRT do
  it "has a version" do
    CRT::VERSION.should eq("0.1.0")
  end

  it "aliases Style from Ansi" do
    CRT::Style.should eq(CRT::Ansi::Style)
  end

  it "aliases Color from Ansi" do
    CRT::Color.should eq(CRT::Ansi::Color)
  end

  it "aliases Border from Ansi" do
    CRT::Border.should eq(CRT::Ansi::Border)
  end
end
