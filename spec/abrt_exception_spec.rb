require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'abrt/exception'

describe "ABRT::Exception" do
  let(:exception) do
    RuntimeError.new("baz").tap do |e|
      e.set_backtrace([
        "/foo/bar.rb:3:in `block in func'",
        "/foo/bar.rb:2:in `each'",
        "/foo/bar.rb:2:in `func'",
        "/foo.rb:2:in `<main>'"
      ])
      e.extend(ABRT::Exception)
    end
  end

  describe "#format" do
    it "provides the formated exception message" do
      expect(exception.format) == [
        "/foo/bar.rb:3:in `block in func': baz (RuntimeError)",
          "\tfrom /foo/bar.rb:2:in `each'",
          "\tfrom /foo/bar.rb:2:in `func'",
          "\tfrom /foo.rb:2:in `<main>'"
      ]
    end
  end

  describe "#executable" do
    it "gets executable from backtrace" do
      expect(exception.executable).to eq("/foo.rb")
    end

    describe "fallbacks to $PROGRAM_NAME" do
      before do
        @orig_program_name = $PROGRAM_NAME
        $PROGRAM_NAME = "/bar.rb"
      end

      after do
        $PROGRAM_NAME = @orig_program_name
      end

      it "when backtrace is empty" do
        exception.set_backtrace([])

        expect(exception.executable).to eq("/bar.rb")
      end

      it "backtrace is not defined" do
        exception.set_backtrace(nil)

        expect(exception.executable).to eq("/bar.rb")
      end
    end
  end

end
