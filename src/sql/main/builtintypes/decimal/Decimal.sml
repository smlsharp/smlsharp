structure SMLSharp_SQL_Decimal =
struct
  type decimal = string

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
