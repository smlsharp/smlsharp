datatype 'a foo = Foo of 'a
and 'b bar = Bar of 'b foo;
val v1 = Bar(Foo 1);
