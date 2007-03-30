
(**
 *  Given a list of instruction definitions, this module generates
 * ML and C code for operation of the IML bytecode.
 * <p>
 *  ML part of the generated code contains:
 * <ul>
 * <li>a "datatype" declaration for IML instructions.</li>
 * <li>a "datatype" declaration for opcode part of IML instructions.</li>
 * <li>functions which translate values of above datatype into a byte array.
 *     They are
 *     <ul>
 *     <li>a function which calculates the number of bytes required to hold
 *         a sequence of the instructions in the binary format.</li>
 *     <li>a function which emit the binary format of instructions into the
 *         byte array.</li>
 *     <li>a function which returns a string representation of a instruction.
 *         </li>
 *     <li>a function which indicates whether two instructions are equal to
 *         each other.</li>
 *     <li>a function which, given a word, return an opcode of it.</li>
 *     <li>a function which returns a string representation of an opcode.</li>
 *     </ul>
 * </ul>
 *  C part of the generated code contains:
 * <ul>
 * <li>an "enum" declaration for opcode.</li>
 * <li>a function which maps opcode of instructions to its display name.</li>
 * </ul>
 *  It is to note that ML or C function which extracts IML instruction
 * out of a given byte array is not generated. It is difficult.
 * </p>
 * 
 * <p>
 *  The input string must conform to the following syntax. This syntax is
 * subset of syntax of ML declaration of structure and datattype.:
 * </p>
 * <pre>
 * structureDefinition ::=
 *     "structure" STRING "=" "struct" datatypeDefinition "end"
 * datatypeDefinition ::=
 *     "datatype" STRING "=" instruction "|" ... "|" instruction
 * instruction ::= opname "of" operands
 * opname ::= STRING
 * operands ::= "{" operand "," ... "," operand "}"
 * operand ::= STRING ":" operandType
 * operandType ::= "UInt8"
 *               | "SInt8"
 *               | "UInt16"
 *               | "SInt16"
 *               | "UInt24"
 *               | "SInt24"
 *               | "UInt32"
 *               | "SInt32"
 *               | "Real32"
 *               | "Real64"
 *               | operandType "list"
 * </pre>
 * <p>
 *  Example:
 * </p>
 * <pre>
 * datatype IMLInstruction = 
 *          LoadConst of { padding : UInt24, constant : SInt32 }
 *        | CallStaticN of
 *          { arity : UInt8, bitmapEntry : UInt16, argEntries : UInt32 list }
 *        | LoadString of { length : UInt24, string : UInt8 list }
 * </pre>
 * @author YAMATODANI Kiyoshi
 * @version $Id: InstructionGenerator.sml,v 1.7 2007/01/10 09:43:45 katsu Exp $
 *)
structure InstructionGenerator :>
  sig

      val CEnumDeclarationKeyword : string
      val CInstructionToStringFunctionKeyword : string
      val SMLDatatypeDeclarationKeyword : string
      val SMLOpcodeDatatypeDeclarationKeyword : string
      val SMLGetSizeOfInstructionFunctionKeyword : string
      val SMLEmitInstructionFunctionKeyword : string
      val SMLInstructionTypeNameKeyword : string
      val SMLInstructionStructureNameKeyword : string
      val SMLInstructionToStringFunctionKeyword : string
      val SMLOpcodeToStringFunctionKeyword : string
      val SMLEqualInstructionFunctionKeyword : string
      val SMLWordToOpcodeFunctionKeyword : string
      val SMLOpcodeToWordFunctionKeyword : string

      val generateFiles : string -> (string list) -> unit

  end =
struct

  (***************************************************************************)

  open InstructionParserTypes;

  (***************************************************************************)

  val CEnumDeclarationKeyword = "@CEnumDeclaration@"
  val CInstructionToStringFunctionKeyword = "@CInstructionToStringFunction@"
  val SMLDatatypeDeclarationKeyword = "@SMLDatatypeDeclaration@"
  val SMLOpcodeDatatypeDeclarationKeyword = "@SMLOpcodeDatatypeDeclaration@"
  val SMLGetSizeOfInstructionFunctionKeyword = "@SMLGetSizeOfInstructin@"
  val SMLEmitInstructionFunctionKeyword = "@SMLEmitInstruction@"
  val SMLInstructionTypeNameKeyword = "@SMLInstructionTypeName@"
  val SMLInstructionStructureNameKeyword = "@SMLInstructionStructureName@"
  val SMLInstructionToStringFunctionKeyword =
      "@SMLInstructionToStringFunction@"
  val SMLOpcodeToStringFunctionKeyword = "@SMLOpcodeToStringFunction@"
  val SMLEqualInstructionFunctionKeyword = "@SMLEqualInstructionFunction@"
  val SMLWordToOpcodeFunctionKeyword = "@SMLWordToOpcodeFunction@"
  val SMLOpcodeToWordFunctionKeyword = "@SMLOpcodeToWordFunction@"

  val BasicTypeStructureName = "BasicTypes"

  val SMLOpcodePrefix = "OPCODE_"

  val OpCodeType = UInt32

  (***************************************************************************)

  fun printError (
                   message,
                   {fileName = fileName1, line = line1, col = column1},
                   {fileName = fileName2, line = line2, col = column2}
                 ) =
      TextIO.output(
                     TextIO.stdOut,
                     String.concat 
                     [
                       fileName1,
                       ":",
                       Int.toString line1,
                       ".",
                       Int.toString column1,
                       "-",
                       Int.toString line2,
                       ".",
                       Int.toString column2,
                       " ",
                       message,
                       "\n"
                     ]);

  (* build parser *)
  structure InstructionLrVals =
            InstructionLrValsFun (structure Token = LrParser.Token);
  structure InstructionLex =
            InstructionLexFun (structure Tokens = InstructionLrVals.Tokens);
  structure InstructionParser = 
	    JoinWithArg
                (structure ParserData = InstructionLrVals.ParserData;
		 structure Lex = InstructionLex;
		 structure LrParser = LrParser);

  exception ParseError;
  fun parseStream (fileName, inStream) = 
      let
          val lexer =
              InstructionParser.makeLexer 
              (fn n => TextIO.inputN (inStream, n))
(*              (fn n => TextIO.inputLine inStream)*)
              {fileName = fileName, printError = printError};
      in
          #1 (InstructionParser.parse (0, lexer, printError, ()))
      end;

  fun parseString string = parseStream ("-", (TextIO.openString string));

  fun parseFile fileName =
      let
          val inStream = TextIO.openIn fileName
      in
          ((parseStream (fileName, inStream))
           handle e => (TextIO.closeIn inStream; raise e))
          before TextIO.closeIn inStream
      end

  (***************************************************************************)

  val CIndent = "  ";
  val SMLIndent = "  ";
  val newLine = "\n";

  fun getNameOfOperandType operandType =
      case operandType of
           UInt8 => "UInt8"
         | SInt8 => "SInt8"
         | UInt16 => "UInt16"
         | SInt16 => "SInt16"
         | UInt24 => "UInt24"
         | SInt24 => "SInt24"
         | UInt32 => "UInt32"
         | SInt32 => "SInt32"
         | Real32 => "Real32"
         | Real64 => "Real64"
         | List elementType => (getNameOfOperandType elementType) ^ " list"

  fun getEmitterOfOperandType operandType =
      case operandType of
           UInt8 => "serializeUInt8"
         | SInt8 => "serializeSInt8"
         | UInt16 => "serializeUInt16"
         | SInt16 => "serializeSInt16"
         | UInt24 => "serializeUInt24"
         | SInt24 => "serializeSInt24"
         | UInt32 => "serializeUInt32"
         | SInt32 => "serializeSInt32"
         | Real32 => "serializeReal32"
         | Real64 => "serializeReal64"

  fun getBytesOfOperandType operandType =
      case operandType of
           UInt8 => 1
         | SInt8 => 1
         | UInt16 => 2
         | SInt16 => 2
         | UInt24 => 3
         | SInt24 => 3
         | UInt32 => 4
         | SInt32 => 4
         | Real32 => 4
         | Real64 => 8
         (* | List elementType *)

  (**
   *  Concat strings with separator.
   *
   *  String.concatWith provides the same functionality, but this function is
   * not implemented by some version of SML/NJ.
   *
   * @params strings -> separator
   * @param string the list of string
   * @param separator the separator
   * @return the concatenation of the strings using the separator
   *)
  fun interleave strings separator =
      String.concat
      (rev
       (foldl
        (fn (string, strings) => string :: separator :: strings)
        [hd strings]
        (tl strings)))

  (***************************************************************************)

  fun generateCEnumDeclaration (structureName, typeName, instructions) =
      let
          fun generateElement ({name, opcode, ...} : instructionDefinition) =
              CIndent ^ name ^ " = " ^ (Int.toString opcode)
      in
          "typedef enum {" ^ newLine ^
          (interleave (map generateElement instructions) (" ," ^ newLine)) ^
          newLine ^
          "} " ^ typeName ^ ";" ^ newLine
      end

  fun generateCInstructionToStringFunction
      (structureName, typeName, instructions) =
      let
          fun generateCase ({name, opcode, ...} : instructionDefinition) =
              CIndent ^ CIndent ^ "case " ^ name ^ ": return \"" ^ name ^ "\";"
      in
          "const char*" ^ newLine ^
          typeName ^ "ToString(" ^ typeName ^ " opcode)" ^ newLine ^
          "{" ^ newLine ^
          CIndent ^ "switch(opcode){" ^ newLine ^
          (interleave (map generateCase instructions) newLine) ^
          newLine ^
          CIndent ^ "}" ^ newLine ^
          "}" ^ newLine
      end

  (****************************************)

  fun generateSMLDatatypeDeclaration (structureName, typeName, instructions) =
      let
          fun generateTyRow (label, operandType) =
              label ^ " : " ^
              BasicTypeStructureName ^ "." ^
              (getNameOfOperandType operandType)
          fun generateValCon ({name, operands, ...} : instructionDefinition) =
              if null operands
              then name
              else
                name ^ " of " ^
                "{" ^ (interleave (map generateTyRow operands) ", ") ^ "}"
      in
          "datatype " ^ typeName ^ " = " ^ newLine ^
          "         " ^ 
          (interleave
           (map generateValCon instructions)
           (newLine ^ "       | ")) ^
          ";" ^ newLine
      end

  fun generateSMLOpcodeDatatypeDeclaration
          (structureName, typeName, instructions) =
      let
          fun generateValCon ({name, ...} : instructionDefinition) =
              SMLOpcodePrefix ^ name
      in
          "datatype " ^ SMLOpcodePrefix ^ typeName ^ " = " ^ newLine ^
          "         " ^ 
          (interleave
           (map generateValCon instructions)
           (newLine ^ "       | ")) ^
          ";" ^ newLine
      end

  fun generateSMLGetSizeOfInstructionFunction
      (structureName, typeName, instructions) =
      let
          fun generatePatRow (label, operandType) = label
          fun generateCalcSize (label, operandType) =
              case operandType of
                  List elementType =>
                      "(" ^
                      (Int.toString (getBytesOfOperandType elementType)) ^
                      " * List.length " ^ label ^
                      ")"
                | _ => Int.toString (getBytesOfOperandType operandType)
          fun generateValCon ({name, operands, ...} : instructionDefinition) =
              if null operands
              then
                structureName ^ "." ^ name ^ " => 4"
              else
                structureName ^ "." ^ name ^
                "{" ^ (interleave (map generatePatRow operands) ", ") ^ "}" ^
                " => 4 + " ^ (interleave (map generateCalcSize operands) " + ")
      in
          "fun getSizeOfInstruction instruction = " ^ newLine ^
          "    case instruction of " ^ newLine ^
          "        " ^
          (interleave
           (map generateValCon instructions)
           (newLine ^ "      | ")) ^
          ";" ^ newLine
      end

  fun generateSMLEmitInstructionFunction
      (structureName, typeName, instructions) =
      let
          fun generatePatRow (label, operandType) = label
          fun generateEmitCode (label, operandType) =
              case operandType of
                  List elementType =>
                      "app" ^
                      " (fn element => " ^
                      (generateEmitCode ("element", elementType)) ^
                      ") " ^ label
                | _ => "BasicTypeSerializer." ^
                       (getEmitterOfOperandType operandType) ^
                       " " ^ label ^ " writer"
          fun generateValCon
              ({name, opcode, operands, ...} : instructionDefinition) =
              if null operands
              then
                structureName ^ "." ^ name ^
                " => let" ^
                " val _ = " ^ "BasicTypeSerializer." ^
                (getEmitterOfOperandType OpCodeType) ^
                " 0w" ^ (Int.toString opcode) ^ " writer" ^
                " in () end"
              else
                structureName ^ "." ^ name ^
                "{" ^ (interleave (map generatePatRow operands) ", ") ^ "}" ^
                " => let" ^
                " val _ = " ^ "BasicTypeSerializer." ^
                (getEmitterOfOperandType OpCodeType) ^
                " 0w" ^ (Int.toString opcode) ^ " writer;" ^
                (interleave
                     (map
                          ((fn s =>" val _ = " ^ s) o generateEmitCode)
                          operands)
                     ";") ^
                " in () end"
      in
          "fun emitInstruction instruction writer = " ^ newLine ^
          "    case instruction of " ^ newLine ^
          "        " ^
          (interleave
           (map generateValCon instructions)
           (newLine ^ "      | ")) ^
          ";" ^ newLine
      end

  fun generateSMLInstructionToStringFunction
      (structureName, typeName, instructions) =
      let
          fun generateToStringOfType operandType =
              case operandType of
                  List elementType =>
                  "ListToString " ^
                  "(" ^ (generateToStringOfType elementType) ^ ") "
                | _ => (getNameOfOperandType operandType) ^ ".toString " 
          fun generatePatRow (label, operandType) = label
          fun generateExpRow (label, operandType) =
              "\"" ^ label ^ " = \" ^ " ^
              "(" ^ (generateToStringOfType operandType) ^ " " ^ label ^ ")"
          fun generateValCon ({name, operands, ...} : instructionDefinition) =
              if null operands
              then
                name ^ " => " ^ "\"" ^ name ^ "\""
              else
                name ^ 
                "{" ^ (interleave (map generatePatRow operands) ", ") ^ "}" ^
                " => " ^
                "\"" ^ name ^
                "{\" ^ " ^
                (interleave (map generateExpRow operands) " ^ \", \" ^ ") ^
                " ^ \"}\""
      in
          "local" ^ newLine ^
          "  fun ListToString f [] = \"[]\"" ^ newLine ^
          "    | ListToString f list = " ^ newLine ^
          "      \"[\" ^ (String.concat" ^ newLine ^
          "      (rev" ^ newLine ^
          "       (foldl" ^ newLine ^
          "        (fn (elem, strings) => (f elem) :: \", \" :: strings)" ^
          newLine ^
          "         [f(hd list)]" ^ newLine ^
          "         (tl list)))) ^ \"]\"" ^  newLine ^
          "in" ^ newLine ^
          "  fun toString instruction = " ^ newLine ^
          "      case instruction of " ^ newLine ^
          "          " ^
          (interleave
           (map generateValCon instructions)
           (newLine ^ "        | ")) ^ newLine ^
          "end;" ^ newLine
      end

  fun generateSMLOpcodeToStringFunction 
          (structureName, typeName, instructions) =
      let
          fun generateValCon ({name, opcode, ...} : instructionDefinition) =
              SMLOpcodePrefix ^ name ^ " => \"" ^ name ^ "\""
      in
          "fun opcodeToString opcode = " ^ newLine ^
          "         case opcode of" ^ newLine ^
          "         " ^ 
          (interleave
           (map generateValCon instructions)
           (newLine ^ "       | ")) ^ 
          ";" ^ newLine
      end

  fun generateSMLEqualInstructionFunction
      (structureName, typeName, instructions) =
      let
          fun generateEqualOfType operandType =
              case operandType of
                  List elementType =>
                  "equalList " ^
                  "(" ^ (generateEqualOfType elementType) ^ ") "
                | _ =>
                  "equal" ^ (getNameOfOperandType operandType)
          fun generatePatRow (label, operandType) = label
          fun generateExpRow (label, operandType) =
              "(" ^ (generateEqualOfType operandType) ^
              " (#" ^ label ^ " left, #" ^ label ^ " right))"
          fun generateValCon ({name, operands, ...} : instructionDefinition) =
              if null operands
              then
                "(" ^ name ^ ", " ^ name ^ ") => true"
              else
                "(" ^ name ^ " left, " ^ name ^ " right)" ^
                " => " ^
                (interleave (map generateExpRow operands) " andalso ")
      in
          "local" ^ newLine ^
          "  fun equalUInt8 pair = EQUAL = UInt8.compare pair" ^ newLine ^
          "  fun equalSInt8 pair = EQUAL = SInt8.compare pair" ^ newLine ^
          "  fun equalUInt16 pair = EQUAL = UInt16.compare pair" ^ newLine ^
          "  fun equalSInt16 pair = EQUAL = SInt16.compare pair" ^ newLine ^
          "  fun equalUInt24 pair = EQUAL = UInt24.compare pair" ^ newLine ^
          "  fun equalSInt24 pair = EQUAL = SInt24.compare pair" ^ newLine ^
          "  fun equalUInt32 pair = EQUAL = UInt32.compare pair" ^ newLine ^
          "  fun equalSInt32 pair = EQUAL = SInt32.compare pair" ^ newLine ^
          "  fun equalReal32 pair = EQUAL = Real32.compare pair" ^ newLine ^
          "  fun equalReal64 pair = EQUAL = Real64.compare pair" ^ newLine ^
          "  fun equalList f (left, right) = " ^ newLine ^
          "      (List.length left = List.length right) andalso " ^ newLine ^
          "       (ListPair.all f (left, right))" ^ newLine ^
          "in" ^ newLine ^
          "  fun equal (left, right) = " ^ newLine ^
          "      case (left, right) of " ^ newLine ^
          "          " ^
          (interleave
           (map generateValCon instructions)
           (newLine ^ "        | ")) ^ newLine ^
          "        | _ => false" ^ newLine ^
          "end;" 
      end

  fun generateSMLWordToOpcodeFunction 
          (structureName, typeName, instructions) =
      let
          fun generateValCon ({name, opcode, ...} : instructionDefinition) =
              "0w" ^ Int.toString opcode ^ " => " ^ SMLOpcodePrefix ^ name
      in
          "fun wordToOpcode (word : " ^ BasicTypeStructureName ^ ".UInt32) = " ^ newLine ^
          "         case word of" ^ newLine ^
          "         " ^ 
          (interleave
           (map generateValCon instructions)
           (newLine ^ "       | ")) ^ newLine ^
          "       | _ => raise Fail (\"Invalid opcode :\" ^ (UInt32.toString word))" ^ 

          ";" ^ newLine
      end

  fun generateSMLOpcodeToWordFunction 
          (structureName, typeName, instructions) =
      let
          fun generateValCon ({name, opcode, ...} : instructionDefinition) =
              SMLOpcodePrefix ^ name ^ " => " ^  "0w" ^ Int.toString opcode
      in
          "fun opcodeToWord opcode = " ^ newLine ^
          "         case opcode of" ^ newLine ^
          "         " ^ 
          (interleave
           (map generateValCon instructions)
           (newLine ^ "       | ")) ^ newLine ^
          ";" ^ newLine
      end

  (***************************************************************************)

  fun generateFiles definitionFileName outputFileNames =
      let
          val fileNamePairs =
              map (fn fileName => (fileName ^ ".in", fileName)) outputFileNames

          val parseResult as (structureName, typeName, _) =
              parseFile definitionFileName

          val SMLDatatypeDeclaration =
              generateSMLDatatypeDeclaration parseResult
          val SMLOpcodeDatatypeDeclaration =
              generateSMLOpcodeDatatypeDeclaration parseResult
          val SMLGetSizeOfInstructionFunction =
              generateSMLGetSizeOfInstructionFunction parseResult
          val SMLEmitInstructionFunction =
              generateSMLEmitInstructionFunction parseResult
          val CInstructionToStringFunction =
              generateCInstructionToStringFunction parseResult
          val CEnumDeclaration =
              generateCEnumDeclaration parseResult
          val SMLInstructionToStringFunction =
              generateSMLInstructionToStringFunction parseResult
          val SMLOpcodeToStringFunction =
              generateSMLOpcodeToStringFunction parseResult
          val SMLEqualInstructionFunction =
              generateSMLEqualInstructionFunction parseResult
          val SMLWordToOpcodeFunction =
              generateSMLWordToOpcodeFunction parseResult
          val SMLOpcodeToWordFunction =
              generateSMLOpcodeToWordFunction parseResult
          val keyValuePairs =
              [
               (SMLDatatypeDeclarationKeyword, SMLDatatypeDeclaration),
               (SMLOpcodeDatatypeDeclarationKeyword,
                SMLOpcodeDatatypeDeclaration),
               (SMLEmitInstructionFunctionKeyword, SMLEmitInstructionFunction),
               (SMLGetSizeOfInstructionFunctionKeyword,
                SMLGetSizeOfInstructionFunction),
               (CInstructionToStringFunctionKeyword,
                CInstructionToStringFunction),
               (CEnumDeclarationKeyword, CEnumDeclaration),
               (SMLInstructionTypeNameKeyword, typeName),
               (SMLInstructionStructureNameKeyword, structureName),
               (SMLInstructionToStringFunctionKeyword,
                SMLInstructionToStringFunction),
               (SMLOpcodeToStringFunctionKeyword, SMLOpcodeToStringFunction),
               (SMLEqualInstructionFunctionKeyword,
                SMLEqualInstructionFunction),
               (SMLWordToOpcodeFunctionKeyword, SMLWordToOpcodeFunction),
               (SMLOpcodeToWordFunctionKeyword, SMLOpcodeToWordFunction)
              ]
      in
          List.app
          (StringReplacer.replaceFile keyValuePairs)
          fileNamePairs
      end

end;
