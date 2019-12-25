fun f modify x = modify # {X = x};

fun reStructure (p as {Salary,...}) = p # {Salary=Salary * (1.0 - 0.0803)};

