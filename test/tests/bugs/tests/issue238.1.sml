fun getbyte 0 = ()
  | getbyte b = getbyte (b << 1);
