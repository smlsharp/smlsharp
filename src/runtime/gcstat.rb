require 'yaml'
require 'pp'

class Hash
  def add_vector(v)
    ret = dup
    v.each { |colname,value|
      if key? colname
      then ret[colname] += value
      else ret[colname] = value
      end
    }
    ret
  end
  def add_table(v)
    ret = dup
    v.each { |rowname,row|
      if key? rowname
      then ret[rowname] = ret[rowname].add_vector row
      else ret[rowname] = row
      end
    }
    ret
  end
end

class GCStat

  class HashDelegate
    def initialize(hash, override = {})
      @__hash__ = hash
      @override = override
    end
    def [](*args, &block)
      @__hash__.[](*args, &block)
    end
    def method_missing(m)
      @override.fetch(m) { @__hash__[m.to_s] }
    end
  end

  class << self
    private :new
  end

  def initialize
    @counters = {}
    @init = {}
    @finish = {}
  end

  def self.load(filename, &block)
    File.open(filename) { |f| parse(f, &block) }
  end

  def self.parse(src)
    init = nil
    last = nil
    YAML.load_documents(src) do |doc|
      event = doc['event']
      ov = {}
      log = HashDelegate.new(doc, ov)

      if event == 'init' then
        bins = doc['config'].keys.sort
        ov[:bins] = bins
        count = (doc['counters'] || {}).inject({}) { |h,(k,v)|
          v = v.inject({}) { |c,i| c.update(i => 0) }
          if k == 'heap' then
            bins.each { |i| h[i] = v }
          else
            h[k] = v
          end
          h
        }
        ov[:count] = count
        init = log
      else
        count = doc['count'] || {}
        ov[:count] = init.count.add_table(count)
      end

      heap = doc['heap'] || {}
      init.bins.each { |i| heap[i] = [] unless heap.key? i }
      ov[:heap] = heap
      ov[:gc?] = (event == 'start gc' || event == 'end gc')
      ov[:init] = init

      yield log
      last = log
    end
    last
  end

end


if $0 == __FILE__ then
  benchinfo = {}

  ARGV.each do |filename|
    total_alloc_log = []
    bin_alloc_log = []
    bin_usage_log = {}
    heap_usage_log = []
    gc_behaviour_log = []
    gc_time_log = []
    count = {}

    finish = GCStat.load(filename) do |log|
      count = count.add_table(log.count)
      gc_signal = log.gc? ? log.init.heap_size : nil

      sum = 0
      count_total = log.init.counters['heap'].map { |colname|
        x = log.init.bins.inject(0) { |z,rowname| z += count[rowname][colname] }
        sum += x
        x
      }
      total_alloc_log.push([log.time, sum] + count_total)

      count_bins = log.init.bins.map { |rowname|
        count[rowname].inject(0) { |z,(colname,value)| z += value }
      }
      bin_alloc_log.push([log.time] + count_bins)

      heap_all = log.init.stack_size || 0
      heap_area = 0
      heap_used = 0
      heap_filled = 0
      heap_count = 0
      log.init.bins.each { |slotsize|
        arenas = log.heap[slotsize]
        bin_all = 0
        bin_area = 0
        bin_used = 0
        bin_filled = 0
        bin_count = 0
        arenas.each { |arena|
          bin_all += log.init.config[slotsize]['size']
          bin_area += slotsize * log.init.config[slotsize]['num_slots']
          bin_used += slotsize * arena['count']
          bin_filled += arena['filled']
          bin_count += arena['count']
        }
        bin_usage_log[slotsize] = [] unless bin_usage_log.key? slotsize
        bin_usage_log[slotsize].push [log.time, gc_signal, bin_all,
                                      bin_area, bin_used, bin_filled]
        heap_all += bin_all
        heap_area += bin_area
        heap_used += bin_used
        heap_filled += bin_filled
        heap_count += bin_count
      }
      heap_usage_log.push [log.time, gc_signal, heap_all,
                           heap_area, heap_used, heap_filled]
      
      if log.event == 'end gc' then
        gc_behaviour_log.push [log.time, heap_count, log.push, log.trace]
        gc_time_log.push [log.time, log.duration, log.clear_time]
      end
    end

    init = finish.init
    basename = File.basename(filename, '.log')

    File.open(basename + "_heap.csv", "w") { |f|
      f.puts "Time,GC signal,All,Total,Consumed,Filled"
      heap_usage_log.each { |i| f.puts i.join(',') }
    }
    init.bins.each { |i|
      File.open(basename + "_#{i}.csv", "w") { |f|
        f.puts "Time,GC signal,All,Total,Consumed,Filled"
        bin_usage_log[i].each { |i| f.puts i.join(',') }
      }
    }
    File.open(basename + '_gc.csv', 'w') { |f|
      f.puts "Time,Lives,Push,Trace"
      f.puts "0,0,0,0"
      gc_behaviour_log.each { |i| f.puts i.join(',') }
    }
    File.open(basename + '_alloc.csv', 'w') { |f|
      f.puts "Time,Total,#{init.counters['heap'].join(',')}"
      total_alloc_log.each { |i| f.puts i.join(',') }
    }
    File.open(basename + '_alloc_size.csv', 'w') { |f|
      f.puts "Time,#{init.bins.join(',')}"
      bin_alloc_log.each { |i| f.puts i.join(',') }
    }

    info = {}
    info['num_samples'] = heap_usage_log.size
    info['limit'] = heap_usage_log[300][0] if heap_usage_log.size > 300
    if finish.event == 'finish' then
      time_summary =
      %'<table>'+
      %'<tr><th>num samples</th><td>#{heap_usage_log.size}</td></tr>'+
      %'<tr><th>exec time</th><td>#{"%.6f" % finish["exec time"]} sec</td>'+
      %'</tr>'+
      %'<tr><th>gc time</th><td>#{"%.6f" % finish["gc time"]} sec</td></tr>'+
      %'<tr><th>gc count</th><td>#{finish["gc count"]}</td></tr>'+
      %'<tr><th>avg gc time</th>'+
      %'<td>#{"%.6f" % (finish["gc time"] / finish["gc count"].to_f)
             } sec</td></tr>'+
      %'<tr><th>clear time</th><td>#{"%.6f" % finish["clear time"]} sec</td>'+
      %'</tr>'+
      %'<tr><th>avg clear time</th>'+
      %'<td>#{"%.6f" % (finish["clear time"] / finish["gc count"].to_f)
             } sec</td></tr>'+
      %'</table>'
    else
      time_summary =
      %'<table>'+
      %'<tr><th>num samples</th><td>#{heap_usage_log.size}</td></tr>'+
      %'<tr><th>exec time</th>'+
      %'<td><strong>ABORTED (#{finish.event})</strong></td></tr>'+
      %'</table>'
    end
    info['timeHTML'] = %'"#{time_summary.gsub(/"/, '\\\\\\&')}"'

    config_html =
    %'<table>'+
    %'<tr><th>heap size</th><td colspan="3">#{init.heap_size} bytes</td></tr>'+
    %'#{if init.stack_size
        then %`<tr><th>stack size</th><td colspan="3">#{stack_size} bytes`
             %"</td></tr>" else "" end}'+
    %'<tr>'+
    %'<th>slot size</th>'+
    %'<th>whole size [bytes]</th>'+
    %'<th>num slots</th>'+
    %'<th>bitmap size [bytes]</th>'+
    %'</tr>'
    p config_html
    init.bins.each { |i|
      config_html <<
      %'<tr>'<<
      %'<td>#{i}</td>'<<
      %'<td>#{init.config[i]["size"]}</td>'<<
      %'<td>#{init.config[i]["num_slots"]}</td>'<<
      %'<td>#{init.config[i]["bitmap_size"]}</td>'<<
      %'</tr>'
    }
    config_html << '</table>'
    info['configHTML'] = %'"#{config_html.gsub(/"/, '\\\\\\&')}"'
    info['gc_count'] = gc_behaviour_log.size
    benchinfo[basename] = info


    p total_alloc_log.last
    p count.inject(0){|z,(k,v)| if k == 'barrier' then z else v.inject(z) { |z,(k,v)| z += v} end }
    p finish['total alloc count']

  end

  puts "var benchInfo = {#{benchinfo.map { |key,info|
          %'"#{key}": {#{info.map{ |k,v| %'"#{k}": #{v}' }.join(',')}}'
        }.join(',')}}"

end
