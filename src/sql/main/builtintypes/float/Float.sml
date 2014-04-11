structure SMLSharp_SQL_Float =
struct
  type float = string

  fun toString x = x : string
  fun fromString x = x : string

  fun toReal x =
      case Real.fromString x of
        SOME x => x
      | NONE => raise SMLSharp_SQL_Errors.Format

  fun toDecimal x =
      case IEEEReal.fromString x of
        SOME x => x
      | NONE => raise SMLSharp_SQL_Errors.Format
end
