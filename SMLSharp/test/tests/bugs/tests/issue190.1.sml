signature STREAM_IO = 
sig
  type vector
end;
signature IMPERATIVE_IO =
sig
  type vector
  structure StreamIO : STREAM_IO
  sharing type vector = StreamIO.vector
end
where type vector = unit
  and type StreamIO.vector = unit;
