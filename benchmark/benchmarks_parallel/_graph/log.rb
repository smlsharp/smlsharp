require 'yaml'

YAML.load($<.read).each do |i|
  next unless i['bench']
  name, lang, impl = i['bench'].split(/_/)
  impl = "baseline#{impl}" if i['runtime'] == 'baseline'
  i['results'].each_with_index do |j,n|
    puts [name, lang, impl, i['size'], i['cutoff'], j['result'], i['ncores'],
          n + 1, j['time'].to_f, i['maxrss']].join('|')
  end
end
