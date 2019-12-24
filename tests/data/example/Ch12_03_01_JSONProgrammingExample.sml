val J = "[{\"name\":\"Joe\", \"age\":21, \"grade\":1.1},"
                 ^ "{\"name\":\"Sue\", \"age\":31, \"grade\":2.0},"
                 ^ "{\"name\":\"Bob\", \"age\":41, \"grade\":3.9}]";
fun getNames l = map #name l;
val j = JSON.import J;
val vl = _json j as {name:string, age:int, grade:real} list;
val nl = getNames vl;
