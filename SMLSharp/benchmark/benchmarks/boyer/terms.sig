signature TERMS =
  sig
    eqtype head;
    datatype term =
      Var of int
    | Prop of head * term list;
    datatype binding = Bind of int * term;      
    val get: string -> head
    and headname: head -> string
    and add_lemma: term -> unit
    and apply_subst: binding list -> term -> term
    and rewrite: term -> term
  end
