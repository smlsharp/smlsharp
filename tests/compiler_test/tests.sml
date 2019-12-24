open SMLUnit.Test

val tests =
  TestList
    [
      TestLabel ("CaseOf", CaseOf.tests),
      TestLabel ("LexicalItem", LexicalItem.tests),
      TestLabel ("Expression", Expression.tests),
      TestLabel ("ScopeRule", ScopeRule.tests),
      TestLabel ("ValDecl", ValDecl.tests),
      TestLabel ("ValRecDecl", ValRecDecl.tests),
      TestLabel ("FunDecl", FunDecl.tests),
      TestLabel ("DatatypeDecl", DatatypeDecl.tests),
      TestLabel ("TypeDecl", TypeDecl.tests),
      TestLabel ("ExceptionDecl", ExceptionDecl.tests),
      TestLabel ("StrDecl", StrDecl.tests),
      TestLabel ("SigDecl", SigDecl.tests),
      TestLabel ("ImportDecl", Import.tests)
    ]
