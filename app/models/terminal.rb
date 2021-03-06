require 'open3'

class Terminal

  BINARY_PATH = (Rails.root + "bin" + "terminal").to_s

  def initialize(width, height)
    @process = Process.new("#{BINARY_PATH} #{width} #{height}")
  end

  def feed(data)
    process.write("d\n#{data.bytesize}\n")
    process.write(data)
  end

  def snapshot
    process.write("p\n")
    lines = Yajl::Parser.new.parse(process.read_line)

    Snapshot.build(lines)
  end

  def cursor
    process.write("c\n")
    c = Yajl::Parser.new.parse(process.read_line)

    Cursor.new(c['x'], c['y'], c['visible'])
  end

  def release
    process.stop
  end

  private

  attr_reader :process

  class Process

    def initialize(command)
      @stdin, @stdout, @thread = Open3.popen2(command)
    end

    def write(data)
      check_thread!
      @stdin.write(data)
    end

    def read_line
      check_thread!
      @stdout.readline.strip
    end

    def stop
      @stdin.close
    end

    private

    def check_thread!
      raise "terminal died, exit code: #{@thread.value.exitstatus}, signaled?: #{@thread.value.signaled?}" unless @thread.alive?
    end
  end

end
