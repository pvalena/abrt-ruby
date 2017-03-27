require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'abrt/handler'

describe "ABRT" do
  describe "#handle_exception" do
    let(:exception) do
      RuntimeError.new("baz").tap do |e|
        e.set_backtrace([
          "/foo/bar.rb:3:in `block in func'",
          "/foo/bar.rb:2:in `each'",
          "/foo/bar.rb:2:in `func'",
          "/foo.rb:2:in `<main>'"
        ])
      end
    end

    let(:exception_report) do
      "PUT / HTTP/1.1\r\n\r\n" +
      "PID=#{Process.pid}\u0000" +
      "EXECUTABLE=/foo.rb\u0000" +
      "ANALYZER=Ruby\u0000" +
      "TYPE=Ruby\u0000" +
      "BASENAME=rbhook\u0000" +
      "REASON=/foo/bar.rb:3:in `block in func': baz (RuntimeError)\u0000" +
      "BACKTRACE=/foo/bar.rb:3:in `block in func': baz (RuntimeError)\n" +
        "\tfrom /foo/bar.rb:2:in `each'\n" +
        "\tfrom /foo/bar.rb:2:in `func'\n" +
        "\tfrom /foo.rb:2:in `<main>'\u0000"
    end

    let(:null_byte_injection_exception) do
      RuntimeError.new("baz\u0000bar").tap do |e|
        e.set_backtrace([
          "/foo\u0000.rb:2:in `<main>'\u0000INJECTION=injected"
        ])
      end
    end

    let(:abrt) do
      allow(ABRT).to receive(:syslog).and_return(syslog)
      allow(ABRT).to receive(:abrt_socket).and_return(nil)
      ABRT
    end

    let(:syslog) do
      double("syslog").as_null_object.tap do |syslog|
        allow(syslog).to receive(:err).with("%s", anything)
      end
    end

    let(:io) { StringIO.new }

    it "handles exceptions" do
      expect(abrt).to receive(:abrt_socket).and_return(io)
      expect(io).to receive(:read).and_return("HTTP/1.1 201 \r\n\r\n")
      expect(syslog).to_not receive(:err)

      abrt.handle_exception exception

      expect(io.string).to eq(exception_report)
    end

    it "does not suffer null byte injection" do
      expect(abrt).to receive(:abrt_socket).and_return(io)
      expect(io).to receive(:read).and_return("HTTP/1.1 201 \r\n\r\n")
      expect(io).to receive(:write).at_least(1).times do |arg|
        expect(arg =~ /\u0000/).to be_nil.or be >= arg.size - 1
      end
      expect(syslog).to_not receive(:err)

      abrt.handle_exception null_byte_injection_exception
    end

    it "logs unhandled exception message into syslog" do
      expect(syslog).to receive(:notice).with("detected unhandled Ruby exception in '/foo.rb'")
      abrt.handle_exception exception
    end

    it "ignores executables with relative path" do
      expect(abrt).to_not receive(:write_dump)

      exception.set_backtrace("./foo.rb:2:in `<main>'")

      abrt.handle_exception exception
    end

    it "ignores oneline scripts" do
      expect(abrt).to_not receive(:write_dump)

      exception.set_backtrace([
        "-e:1:in `/'",
        "-e:1:in `<main>'"
      ])

      abrt.handle_exception exception
    end

    context "logs error into syslog when" do
      it "receive empty response" do
        expect(abrt).to receive(:abrt_socket).and_return(io)
        expect(syslog).to receive(:err).with("error sending data to ABRT daemon. Empty response received")

        abrt.handle_exception exception
      end

      it "receive malformed response" do
        expect(abrt).to receive(:abrt_socket).and_return(io)
        expect(io).to receive(:read).and_return("foo")
        expect(syslog).to receive(:err).with("%s", "error sending data to ABRT daemon: foo")

        abrt.handle_exception exception
      end

      it "receive error code" do
        expect(abrt).to receive(:abrt_socket).and_return(io)
        expect(io).to receive(:read).and_return("HTTP/1.1 400 \r\n\r\n")
        expect(syslog).to receive(:err).with("%s", "error sending data to ABRT daemon: HTTP/1.1 400 \r\n\r\n")

        abrt.handle_exception exception
      end

      context "can't communicate with ABRT daemon" do
        it "due to non-existing socket" do
          socket_path = 'some/non/existing/path/to/socket'
          expect(abrt).to receive(:abrt_socket).and_wrap_original do |original_method, *args, &block|
            args << socket_path
            original_method.call(*args)
          end
          expect(syslog).to receive(:err).with("%s", /can't communicate with ABRT daemon, is it running\? No such file or directory -( connect\(2\) for)? #{socket_path}/)
          abrt.handle_exception exception
        end

        it "because no-one is listeing on the other side" do
          # This file is not correct UNIX socket, so it should be usable for the test.
          socket_path = __FILE__
          expect(abrt).to receive(:abrt_socket).and_wrap_original do |original_method, *args, &block|
            args << __FILE__
            original_method.call(*args)
          end
          expect(syslog).to receive(:err).with("%s", /can't communicate with ABRT daemon, is it running\? Connection refused -( connect\(2\) for)? #{socket_path}/)
          abrt.handle_exception exception
        end
      end
    end
  end
end
