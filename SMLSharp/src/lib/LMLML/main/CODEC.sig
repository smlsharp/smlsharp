(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: CODEC.sig,v 1.1.28.2 2010/05/06 06:51:47 kiyoshiy Exp $
 *)
signature CODEC =
sig

  structure String : MULTI_BYTE_STRING

  structure Char : MULTI_BYTE_CHAR

  structure Substring : MULTI_BYTE_SUBSTRING

  structure ParserCombinator : MULTI_BYTE_PARSER_COMBINATOR

  structure StringConverter : MULTI_BYTE_STRING_CONVERTER

  sharing type Char.string = String.string
  sharing type Char.char = String.char
  sharing type Substring.string = String.string
  sharing type Substring.char = String.char
  sharing type ParserCombinator.string = String.string
  sharing type ParserCombinator.char = String.char
  sharing type StringConverter.string = String.string
  sharing type StringConverter.char = String.char

end