functor F() =
struct
  val x = 1
  exception Foo
end

structure G =
struct
  val y = 0
  exception Hoge
  exception Hage = Hoge
end
