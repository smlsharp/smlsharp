structure BuiltinContextSources : sig

  val sources : {name: string, body: string} list

end =
struct

  val sources =
      [BuiltinContextCoreSource.source,
       BuiltinContextSQLSource.source]
end
