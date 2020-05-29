  val conn = SQL.connect (
      _sqlserver "dbname=es_db" : {
         projects:{
            code:string,
            name:string,
            start_date:string,
            finish_date:string
         } list,
         progress:{
            code:int,
            project_code:string,
            progress:int,
            input_date:string
         } list
      })

  fun insertProgressByProjectCode (projectCode:string, progress:int) = 
      let
        val now = Time.toString (Time.now ())
        val query =
          _sql db =>
            insert into #db.progress (code, input_date, progress, project_code)
            values (
               default,
               now,
               progress,
               projectCode
            )
      in
        if progress = 0
        then ()
        else query conn
      end
(* 2013-7-26 ohori 
   This causes an unexpected type error.
   This seems to be a bug that re-appear probably due to the
   incomplete recover of my PC crash.
*)
(* 2013-08-07 ohori 
   fixed
*)
