(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: InstructionParserTypes.sml,v 1.2 2004/09/20 13:27:58 kiyoshiy Exp $
 *)
structure InstructionParserTypes = 
struct

  (**
   *  Represents the types of operands of IML instruction
   *)
  datatype operandType =
           UInt8 (** unsigned 8 bit integer *)
         | SInt8 (** signed 8 bit integer *)
         | UInt16 (** unsigned 16 bit integer *)
         | SInt16 (** signed 16 bit integer *)
         | UInt24 (** unsigned 24 bit integer *)
         | SInt24 (** signed 24 bit integer *)
         | UInt32 (** unsigned 32 bit integer *)
         | SInt32 (** signed 32 bit integer *)
         | Real64 (** 64 bit real *)
         | List of operandType (** list *)

  type position = {fileName:string, line:int, col:int}
  type location = position * position

  (**
   *  Represents IML instruction definition
   *)
  type instructionDefinition =
       {
         (** name of the instruction *)
         name : string,
         (** the opcode of the instruction *)
         opcode : int,
         (**
          * list of pairs of the name of the operand and its type
          *)
         operands : (string * operandType) list,
         (**
          * the location where this instruction is defined
          *)
         location : location
       };

end