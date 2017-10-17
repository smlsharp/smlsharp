type testDB = {
  評価用 : {
    可変長 : string,
    可変長２ : string,
    費用 : real,
    実数 : Real32.real,
    実数2 : SQL.decimal,
    実数3 : SQL.decimal
  } list
}

val c = SQL.connect (_sqlserver SQL.odbc "DSN user pass" : testDB)
handle e as SQL.Link x => (print ("Link " ^ x ^ "\n"); raise e)
     | e as SQL.Connect x => (print ("Connect " ^ x ^ "\n"); raise e)
     | e as Fail x => (print ("Fail " ^ x ^ "\n"); raise e)
     | e as SQL.Format => (print ("Format \n"); raise e)

(* decimalの追加漏れによるバグ．修正済み *)
