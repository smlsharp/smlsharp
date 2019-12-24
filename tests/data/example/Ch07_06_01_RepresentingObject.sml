fn self => fn x => self := (!self # {X = x});

val pointClass =
{
  getX = fn self => #X (!self),
  setX = fn self => fn x => self := (!self # {X = x}),
  getY = fn self => #Y (!self),
  setY = fn self => fn x => self := (!self # {Y = x}),
  getColor = fn self => #Color (!self),
  setColor = fn self => fn x => self := (!self # {Color = x})
};

local
  val state = ref { X = 0.0, Y = 0.0 }
in 
  val myPoint = fn method => method pointClass state
end;

local
  val state = ref { X = 0.0, Y = 0.0, Color = "Red" }
in 
  val myColorPoint = fn method => method pointClass state
end;

myPoint # setX 1.0;
myPoint # getX;
myColorPoint # getX;
myColorPoint # getColor;
myPoint # getColor;
