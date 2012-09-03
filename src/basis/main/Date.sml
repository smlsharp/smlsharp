(**
 * Date structure.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "Date.smi"

structure Date :> DATE =
struct

  datatype weekday = Mon | Tue | Wed | Thu | Fri | Sat | Sun
  datatype month = Jan | Feb | Mar | Apr | May | Jun
                   | Jul | Aug | Sep | Oct | Nov | Dec
  datatype date = FIXME
  exception Date
  val date : {year : int, month : month, day : int, hour : int, minute : int,
              second : int, offset : Time.time option} -> date =
      fn _ => raise Fail "FIXME: Date.date: not implemented yet"
  val year : date -> int =
      fn _ => raise Fail "FIXME: Date.year: not implemented yet"
  val month : date -> month =
      fn _ => raise Fail "FIXME: Date.month: not implemented yet"
  val day : date -> int =
      fn _ => raise Fail "FIXME: Date.day: not implemented yet"
  val hour : date -> int =
      fn _ => raise Fail "FIXME: Date.hour: not implemented yet"
  val minute : date -> int =
      fn _ => raise Fail "FIXME: Date.minute: not implemented yet"
  val second : date -> int =
      fn _ => raise Fail "FIXME: Date.second: not implemented yet"
  val weekDay : date -> weekday =
      fn _ => raise Fail "FIXME: Date.weekDay: not implemented yet"
  val yearDay : date -> int =
      fn _ => raise Fail "FIXME: Date.yearDay: not implemented yet"
  val offset : date -> Time.time option =
      fn _ => raise Fail "FIXME: Date.offset: not implemented yet"
  val isDst : date -> bool option =
      fn _ => raise Fail "FIXME: Date.isDst: not implemented yet"
  val localOffset : unit -> Time.time =
      fn _ => raise Fail "FIXME: Date.localOffset: not implemented yet"
  val fromTimeLocal : Time.time -> date =
      fn _ => raise Fail "FIXME: Date.fromTimeLocal: not implemented yet"
  val fromTimeUniv : Time.time -> date =
      fn _ => raise Fail "FIXME: Date.fromTimeUniv: not implemented yet"
  val toTime : date -> Time.time =
      fn _ => raise Fail "FIXME: Date.toTime: not implemented yet"
  val compare : date * date -> order =
      fn _ => raise Fail "FIXME: Date.compare: not implemented yet"
  val fmt : string -> date -> string =
      fn _ => raise Fail "FIXME: Date.fmt: not implemented yet"
  val toString : date -> string =
      fn _ => raise Fail "FIXME: Date.toString: not implemented yet"
  val scan : (char, 'a) StringCvt.reader -> (date, 'a) StringCvt.reader =
      fn _ => raise Fail "FIXME: Date.scan: not implemented yet"
  val fromString : string -> date option =
      fn _ => raise Fail "FIXME: Date.fromString: not implemented yet"

end
