#!/usr/bin/ruby

require 'gcstat'

class Array
  def sum
    inject(0) { |z,i| z += i }
  end
  def avg
    sum.to_f / size
  end
end

print <<END
\\documentclass{jarticle}
\\usepackage{multirow}
\\setlength\\oddsidemargin{-1truein}
\\begin{document}\\tiny
\\begin{tabular}{|c|r|r|r|r|r|r|r|r|}\\hline
\\multirow{2}{*}{benchmark}
& \\multirow{2}{*}{heap size}
& \\multirow{2}{*}{gc count}
& \\multicolumn{3}{|c|}{occupancy}
& \\multicolumn{3}{|c|}{live objects}\\\\\\cline{4-9}
&&& min & avg & max & min & avg & max\\\\\\hline
END

ARGV.each do |filename|
  occupancy = []
  live = []
  whole = 0

  fin = GCStat.load(filename) do |log|
    filled = log.heap.inject({}) { |z,(k,v)|
      v.inject(z) { |z,v| z.add_vector(v) }
    }['filled']
    case log.event
    when 'start gc' then occupancy.push filled
    when 'end gc' then live.push filled unless log.gc_type == 'MINOR'
    end
  end
  init = fin.init
  if init.stack_size then
    whole = init.config.inject(0){|z,(k,v)| z += v['size']}
    whole += init.stack_size
  else
    whole = init.heap_size
  end

  puts '%'
  printf "\\verb|%s|\n" \
         "&%8u  %% whole heap size\n" \
         "&%8u  %% gc count\n" \
         "%%  min              &  average          &  max\n" \
         "&%8u (%5.2f\\%%) &%8u (%5.2f\\%%) &%8u (%5.2f\\%%)   %% occupancy\n" \
         "&%8u (%5.2f\\%%) &%8u (%5.2f\\%%) &%8u (%5.2f\\%%)\\\\ %% lives\n" \
         "\\hline\n",
    filename,
    whole,
    fin['gc count'],
    occupancy.min, occupancy.min.to_f / whole * 100.0,
    occupancy.avg, occupancy.avg / whole * 100.0,
    occupancy.max, occupancy.max.to_f / whole * 100.0,
    live.min, live.min.to_f / whole * 100.0,
    live.avg, live.avg / whole * 100.0,
    live.max, live.max.to_f / whole * 100.0
end

print <<END
\\end{tabular}
\\end{document}
END
