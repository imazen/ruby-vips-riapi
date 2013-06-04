require 'benchmark'

#
# multi-benchmark.rb - an extension of the standard benchmark library
#
module MultiBenchmark

  # Executes a block multiple times and displays runtime statistics.

  def self.repeat(count) # :yield: report
    sync = STDOUT.sync
    STDOUT.sync = true
    
    report = Report.new(count)
    yield report

    rows = [ ["x#{count}", 'user', 'system', 'total', 'real'] ] +
      report.list.map { |tms| tms.to_a.map { |str| str.to_s } }

    column_lengths = rows                         \
      .map { |row| row.map { |str| str.length } } \
      .transpose                                  \
      .map { |lengths| lengths.max }

    rows.each do |tms|
      tms.to_a.zip(column_lengths).each do |x|
        print x[0].ljust(x[1] + 1)
      end
      print "\n"
    end

    report.list
  ensure
    STDOUT.sync = sync unless sync.nil?
  end

  #
  # Class used to collect measurements over multiple blocks.
  #

  class Report
    attr_reader :list

    # Returns an initialized Report instance.
    # Each code block will be executed +count+ times.

    def initialize(count)
      @count, @list = count, []
    end

    # Runs a given code block multiple times and records runtime statistics.

    def report(label, &block) # :yield:
      n  = 0
      m1 = Benchmark::Tms.new
      m2 = Benchmark::Tms.new
      @count.times do
        x = Benchmark.measure { block.call }
        delta = x - m1
        n  += 1
        m1 += delta / n
        m2 += delta * (x - m1)
      end

      var = m2 / (n - 1)

      utime = Measurement.new(m1.utime, Math::sqrt(var.utime))
      stime = Measurement.new(m1.stime, Math::sqrt(var.stime))
      total = Measurement.new(m1.total, Math::sqrt(var.total))
      real  = Measurement.new(m1.real,  Math::sqrt(var.real))

      @list << Tms.new(label, utime, stime, total, real)
    end
  end

  #
  # Individual measurements.
  #

  class Measurement
    attr_reader :mean
    attr_reader :std_dev

    def initialize(mean, std_dev)
      @mean, @std_dev = mean, std_dev
    end

    def to_s
      sprintf('%.2f(%.2f)', mean, std_dev)
    end
  end

  #
  # A code block's performance data.
  #

  class Tms
    attr_reader :label  # Label
    attr_reader :utime  # User CPU time
    attr_reader :stime  # System CPU time
    attr_reader :real   # Elapsed real time
    attr_reader :total  # Total time, that is +utime+ + +stime+ + +cutime+ + +cstime+

    def initialize(label, utime, stime, total, real)
      @label, @utime, @stime, @total, @real = label, utime, stime, total, real
    end

    def to_a
      [ @label, @utime, @stime, @total, @real ]
    end
  end
end
