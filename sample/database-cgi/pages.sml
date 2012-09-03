structure Pages : sig

  val dispatch : {method: string, uri: string, args: string} -> string

end =
struct

  val dbserver =
      _sqlserver "dbname=dbsample user=dbsample"
      : {
          posts: {post_id: int,
                  name: string,
                  title: string,
                  body: string},
          comments: {comment_id: int,
                     post_id: int,
                     name: string,
                     body: string}
        }

  fun connect f =
      let
        val conn = SQL.connect dbserver
      in
        Try.try (fn _ => f conn)
        Try.finally (fn _ => SQL.closeConn conn)
      end

  fun exec query conn =
      let
        val r = query conn
      in
        Try.try (fn _ => SQL.fetchAll r)
        Try.finally (fn _ => SQL.closeRel r)
      end

  fun execOne query conn =
      let
        val r = query conn
      in
        Try.try (fn _ => SQL.fetchOne r)
        Try.finally (fn _ => SQL.closeRel r)
      end

  fun idarg args =
      case Int.fromString args of
        NONE => raise CGI.HTTPNotFound
      | SOME x => x

  fun listPostsURI () =
      "list_posts"
  fun viewPostURI post_id =
      "view_post?" ^ Int.toString post_id
  fun newPostURI () =
      "new_post"
  fun doNewPostURI () =
      "do_new_post"
  fun editPostURI post_id =
      "edit_post?" ^ Int.toString post_id
  fun doEditPostURI () =
      "do_edit_post"
  fun deletePostURI post_id =
      "delete_post?" ^ Int.toString post_id
  fun doDeletePostURI () =
      "do_delete_post"
  fun doNewCommentURI () =
      "do_new_comment"
  fun editCommentURI comment_id =
      "edit_comment?" ^ Int.toString comment_id
  fun doEditCommentURI () =
      "do_edit_comment"
  fun deleteCommentURI comment_id =
      "delete_comment?" ^ Int.toString comment_id
  fun doDeleteCommentURI () =
      "do_delete_comment"

  fun lines s =
      String.translate (fn #"\n" => "<br>\n" | c => str c) s

  fun viewPostForm {post_id, name, title, body} =
      "<table>\n\
      \<tbody>\n\
      \<tr><th>ID</th><td>" ^ Int.toString post_id ^ "</td></tr>\n\
      \<tr><th>Name</th><td>" ^ CGI.escapeHTML name ^ "</td></tr>\n\
      \<tr><th>Title</th><td>" ^ CGI.escapeHTML title ^ "</td></tr>\n\
      \<tr><th>Body</th><td><p>" ^ lines (CGI.escapeHTML body) ^
      "</p></td></tr>\n\
      \</tbody>\n\
      \</table>\n"

  fun editPostForm {post_id, name, title, body} =
      "<table>\n\
      \<tbody>\n" ^
      (case post_id of
         NONE => ""
       | SOME id => "<tr><th>ID</th><td>" ^ Int.toString id ^
                    "<input type=\"hidden\" name=\"post_id\"\
                    \ value=\"" ^ Int.toString id ^ "\"></td></tr>\n") ^
      "<tr><th>Name</th><td>\
      \<input type=\"text\" name=\"name\" value=\"" ^
      CGI.escapeHTML name ^ "\">\
      \</td></tr>\n\
      \<tr><th>Title</th><td>\
      \<input type=\"text\" name=\"title\" value=\"" ^
      CGI.escapeHTML title ^ "\">\
      \</td></tr>\n\
      \<tr><th>Body</th><td><textarea name=\"body\" rows=\"8\" cols=\"60\">" ^
      CGI.escapeHTML body ^ "</textarea></td></tr>\n\
      \</tbody>\n\
      \</table>\n"

  fun viewCommentForm {comment_id, post_id, name, body} =
      "<table>\n\
      \<tbody>\n\
      \<tr><th>ID</th><td>" ^ Int.toString comment_id ^ "</td></tr>\n\
      \<tr><th>Post ID</th><td><a href=\"" ^ viewPostURI post_id ^ "\">" ^
      Int.toString post_id ^ "</a></td></tr>\n\
      \<tr><th>Name</th><td>" ^ CGI.escapeHTML name ^ "</td></tr>\n\
      \<tr><th>Body</th><td><p>" ^ lines (CGI.escapeHTML body) ^
      "</p></td></tr>\n\
      \</tbody>\n\
      \</table>\n"

  fun editCommentForm {comment_id, post_id, name, body} =
      "<table>\n\
      \<tbody>\n" ^
      (case comment_id of
         NONE => ""
       | SOME id => "<tr><th>ID</th><td>" ^ Int.toString id ^
                    "<input type=\"hidden\" name=\"comment_id\"\
                    \ value=\"" ^ Int.toString id ^ "\"></td></tr>\n") ^
      "<tr><th>Post ID</th><td><a href=\"" ^ viewPostURI post_id ^ "\">" ^
      Int.toString post_id ^ "</a>\
      \<input type=\"hidden\" name=\"post_id\" value=\"" ^
      Int.toString post_id ^ "\"></td></tr>\n\
      \<tr><th>Name</th><td>\
      \<input type=\"text\" name=\"name\" value=\"" ^
      CGI.escapeHTML name ^ "\">\
      \</td></tr>\n\
      \<tr><th>Body</th><td><textarea name=\"body\" rows=\"8\" cols=\"60\">" ^
      CGI.escapeHTML body ^ "</textarea></td></tr>\n\
      \</tbody>\n\
      \</table>\n"

  fun header title =
      "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\">\n\
      \<html>\n\
      \<head><title>" ^ CGI.escapeHTML title ^ "</title></head>\n\
      \<body>\n\
      \<h1>" ^ CGI.escapeHTML title ^ "</h1>\n"

  fun footer () =
      "</body></html>\n"

  fun listPosts () =
      let
        val q = _sql db => select #post.post_id as post_id,
            #post.name as name,
            #post.title as title
                        from #db.posts as post
        val posts =
            connect (exec (_sqleval q))
      in
        header "List of posts" ^
        "<p><a href=\"" ^ newPostURI () ^ "\">New post</a></p>\n\
        \<table>\n\
        \<thead>\n\
        \<tr><th>ID</th><th>Name</th><th>Title</th>\
        \<th>edit</th><th>delete</th></tr>\n\
        \</thead>\n\
        \<tbody>\n" ^
        (concat
           (map (fn {post_id, name, title} =>
                    "<tr>\
                    \<td>" ^ Int.toString post_id ^ "</td>\n\
                    \<td>" ^ CGI.escapeHTML name ^ "</td>\n\
                    \<td><a href=\"" ^ viewPostURI post_id ^ "\">\
                    \" ^ CGI.escapeHTML title ^ "</a></td>\n\
                    \<td><a href=\"" ^ editPostURI post_id ^ "\">edit</a>\
                    \</td>\n\
                    \<td><a href=\"" ^ deletePostURI post_id ^ "\">delete</a>\
                    \</td>\n\
                    \</tr>\n")
                posts)) ^
        "</tbody></table>\n" ^
        footer ()
      end

  fun viewPost args =
      let
        val post_id = idarg args
        val {post_id, name, title, body, comments} =
            connect
              (fn conn =>
                  let
                    val q =
                        _sql db => select #post.post_id as post_id,
                                          #post.name as name,
                                          #post.title as title,
                                          #post.body as body
                                   from #db.posts as post
                                   where SQL.== (#post.post_id,
                                                 SQL.toSQL post_id)
                    val {post_id, name, title, body} =
                        execOne (_sqleval q) conn

                    val q =
                        _sql db => select #c.comment_id as comment_id,
                                          #c.name as name,
                                          #c.body as body
                                   from #db.comments as c
                                   where SQL.== (#c.post_id, SQL.toSQL post_id)
                    val comments = exec (_sqleval q) conn
                  in
                    {post_id = post_id,
                     name = name,
                     title = title,
                     body = body,
                     comments = comments}
                  end)
      in
        header ("Post " ^ Int.toString post_id) ^
        viewPostForm {post_id = post_id, name = name, title = title,
                      body = body} ^
        "<h2>Comments</h2>\n\
        \<dl>\n" ^
        (concat
           (map (fn {comment_id, name, body} =>
                    "<dt>" ^ CGI.escapeHTML name ^ " \
                    \(<a href=\"" ^ editCommentURI comment_id ^ "\">edit</a>\
                    \ | \
                    \<a href=\"" ^ deleteCommentURI comment_id ^ "\">\
                    \delete</a>)\
                    \</dt>\n\
                    \<dd><p>" ^ lines (CGI.escapeHTML body) ^ "</p></dd>\n")
                comments)) ^
        "</dl>\n\
        \<h2>New comment</h2>\n\
        \<form method=\"post\" action=\"" ^ doNewCommentURI () ^ "\">\n" ^
        editCommentForm {comment_id = NONE, post_id = post_id,
                         name = "", body = ""} ^
        "<div>\n\
        \<input type=\"submit\" value=\"Submit\">&nbsp;\n\
        \<input type=\"reset\" value=\"Reset\">\n\
        \</div>\n\
        \</form>\n\
        \<p><a href=\"" ^ listPostsURI () ^ "\">List of posts</a></p>\n" ^
        footer ()
      end

  fun newPost () =
      header "New post" ^
      "<form method=\"post\" action=\"" ^ doNewPostURI () ^ "\">\n" ^
      editPostForm {post_id = NONE, name = "", title = "", body = ""} ^
      "<div>\n\
      \<input type=\"submit\" value=\"Submit\">&nbsp;\n\
      \<input type=\"reset\" value=\"Reset\">\n\
      \</div>\n\
      \</form>\n\
      \<p><a href=\"" ^ listPostsURI () ^ "\">List of posts</a></p>\n" ^
      footer ()

  fun doNewPost args =
      let
        val args = CGI.splitFormURLEncoded args
        val (name, args) = CGI.fetchFormField "name" SOME args
        val (title, args) = CGI.fetchFormField "title" SOME args
        val (body, args) = CGI.fetchFormField "body" SOME args
        val q =
            _sql db => insert into #db.posts (post_id, name, title, body)
                       values (default, SQL.toSQL name, SQL.toSQL title,
                               SQL.toSQL body)
        val () = connect (_sqlexec q)
      in
        header "New post is accepted" ^
        "<p><a href=\"" ^ listPostsURI () ^ "\">List of posts</a></p>\n" ^
        footer ()
      end

  fun editPost args =
      let
        val post_id = idarg args
        val q =
            _sql db => select #post.post_id as post_id,
                              #post.name as name,
                              #post.title as title,
                              #post.body as body
                       from #db.posts as post
                       where SQL.== (#post.post_id, SQL.toSQL post_id)
        val {post_id, name, title, body} =
            connect (execOne (_sqleval q))
      in
        header ("Edit post " ^ Int.toString post_id) ^
        "<form method=\"post\" action=\"" ^ doEditPostURI () ^ "\">\n" ^
        editPostForm {post_id = SOME post_id, name = name, title = title,
                      body = body} ^
        "<div>\n\
        \<input type=\"submit\" value=\"Submit\">&nbsp;\n\
        \<input type=\"reset\" value=\"Reset\">\n\
        \</div>\n\
        \</form>\n\
        \<p><a href=\"" ^ listPostsURI () ^ "\">List of posts</a></p>\n" ^
        footer ()
      end

  fun doEditPost args =
      let
        val args = CGI.splitFormURLEncoded args
        val (post_id, args) = CGI.fetchFormField "post_id" Int.fromString args
        val (name, args) = CGI.fetchFormField "name" SOME args
        val (title, args) = CGI.fetchFormField "title" SOME args
        val (body, args) = CGI.fetchFormField "body" SOME args
        val q =
            _sql db => update #db.posts as post
                       set (post_id, name, title, body)
                           = (SQL.toSQL post_id,
                              SQL.toSQL name,
                              SQL.toSQL title,
                              SQL.toSQL body)
                       where SQL.== (#post.post_id, SQL.toSQL post_id)
        val () = connect (_sqlexec q)
      in
        header ("Post " ^ Int.toString post_id ^ " updated") ^
        "<p><a href=\"" ^ viewPostURI post_id ^ "\">\
        \View post " ^ Int.toString post_id ^ "</a></p>\n" ^
        footer ()
      end

  fun deletePost args =
      let
        val post_id = idarg args
        val q =
            _sql db => select #post.post_id as post_id,
                              #post.name as name,
                              #post.title as title,
                              #post.body as body
                       from #db.posts as post
                       where SQL.== (#post.post_id, SQL.toSQL post_id)
        val post = connect (execOne (_sqleval q))
      in
        header ("Confirm to delete post " ^ Int.toString post_id) ^
        viewPostForm post ^
        "<form method=\"post\" action=\"" ^ doDeletePostURI () ^ "\">\n" ^
        "<div>\n\
        \<input type=\"hidden\" name=\"post_id\" value=\"" ^
        Int.toString post_id ^ "\">\n\
        \<input type=\"submit\" value=\"Delete\">&nbsp;\n\
        \</div>\n\
        \</form>\n\
        \<p><a href=\"" ^ listPostsURI () ^ "\">List of posts</a></p>\n" ^
        footer ()
      end

  fun doDeletePost args =
      let
        val args = CGI.splitFormURLEncoded args
        val (post_id, args) = CGI.fetchFormField "post_id" Int.fromString args
      in
        connect
          (fn conn =>
              let
                val q =
                    _sql db => delete from #db.comments as c
                               where SQL.== (#c.post_id, SQL.toSQL post_id)
                val () = _sqlexec q conn
                val q = 
                    _sql db => delete from #db.posts as post
                               where SQL.== (#post.post_id, SQL.toSQL post_id)
              in
                _sqlexec q conn
              end);
        header ("Post " ^ Int.toString post_id ^ " deleted") ^
        "<p><a href=\"" ^ listPostsURI () ^ "\">List of posts</a></p>\n" ^
        footer ()
      end

  fun doNewComment args =
      let
        val args = CGI.splitFormURLEncoded args
        val (post_id, args) = CGI.fetchFormField "post_id" Int.fromString args
        val (name, args) = CGI.fetchFormField "name" SOME args
        val (body, args) = CGI.fetchFormField "body" SOME args
        val q =
            _sql db => insert into #db.comments
                              (comment_id, post_id, name, body)
                       values (default, SQL.toSQL post_id,
                               SQL.toSQL name, SQL.toSQL body)
        val () = connect (_sqlexec q)
      in
        header "New comment is accepted" ^
        "<p><a href=\"" ^ viewPostURI post_id ^ "\">\
        \View post " ^ Int.toString post_id ^ "</a></p>\n" ^
        footer ()
      end

  fun editComment args =
      let
        val comment_id = idarg args
        val q =
            _sql db => select #c.comment_id as comment_id,
                              #c.post_id as post_id,
                              #c.name as name,
                              #c.body as body
                       from #db.comments as c
                       where SQL.== (#c.comment_id, SQL.toSQL comment_id)
        val {comment_id, post_id, name, body} =
            connect (execOne (_sqleval q))
      in
        header ("Edit comment " ^ Int.toString comment_id) ^
        "<form method=\"post\" action=\"" ^ doEditCommentURI () ^ "\">\n" ^
        editCommentForm {comment_id = SOME comment_id, post_id = post_id,
                         name = name, body = body} ^
        "<div>\n\
        \<input type=\"submit\" value=\"Submit\">&nbsp;\n\
        \<input type=\"reset\" value=\"Reset\">\n\
        \</div>\n\
        \</form>\n\
        \<p><a href=\"" ^ viewPostURI post_id ^ "\">\
        \View post " ^ Int.toString post_id ^ "</a></p>\n" ^
        footer ()
      end

  fun doEditComment args =
      let
        val args = CGI.splitFormURLEncoded args
        val (comment_id, args) =
            CGI.fetchFormField "comment_id" Int.fromString args
        val (name, args) = CGI.fetchFormField "name" SOME args
        val (body, args) = CGI.fetchFormField "body" SOME args
        val post_id =
            connect
              (fn conn =>
                  let
                    val q =
                        _sql db => select #c.post_id as post_id
                                   from #db.comments as c
                                   where SQL.== (#c.comment_id,
                                                 SQL.toSQL comment_id)
                    val {post_id} = execOne (_sqleval q) conn

                    val q =
                        _sql db => update #db.comments as c
                                   set (comment_id, post_id, name, body)
                                       = (SQL.toSQL comment_id,
                                          SQL.toSQL post_id,
                                          SQL.toSQL name,
                                          SQL.toSQL body)
                                   where SQL.== (#c.comment_id,
                                                 SQL.toSQL comment_id)
                    val () = _sqlexec q conn
                  in
                    post_id
                  end)
      in
        header ("Comment " ^ Int.toString comment_id ^ " updated") ^
        "<p><a href=\"" ^ viewPostURI post_id ^ "\">\
        \View post " ^ Int.toString post_id ^ "</a></p>\n" ^
        footer ()
      end

  fun deleteComment args =
      let
        val comment_id = idarg args
        val q =
            _sql db => select #c.comment_id as comment_id,
                              #c.post_id as post_id,
                              #c.name as name,
                              #c.body as body
                       from #db.comments as c
                       where SQL.== (#c.comment_id, SQL.toSQL comment_id)
        val comment as {post_id,...} =
            connect (execOne (_sqleval q))
      in
        header ("Confirm to delete comment " ^ Int.toString comment_id) ^
        viewCommentForm comment ^
        "<form method=\"post\" action=\"" ^ doDeleteCommentURI () ^ "\">\n" ^
        "<div>\n\
        \<input type=\"hidden\" name=\"comment_id\" value=\"" ^
        Int.toString comment_id ^ "\">\n\
        \<input type=\"submit\" value=\"Delete\">&nbsp;\n\
        \</div>\n\
        \</form>\n\
        \<p><a href=\"" ^ viewPostURI post_id ^ "\">\
        \View post " ^ Int.toString post_id ^ "</a></p>\n" ^
        footer ()
      end

  fun doDeleteComment args =
      let
        val args = CGI.splitFormURLEncoded args
        val (comment_id, args) =
            CGI.fetchFormField "comment_id" Int.fromString args
        val post_id =
            connect
              (fn conn =>
                  let
                    val q =
                        _sql db => select #c.post_id as post_id
                                   from #db.comments as c
                                   where SQL.== (#c.comment_id,
                                                 SQL.toSQL comment_id)
                    val {post_id} = execOne (_sqleval q) conn

                    val q =
                        _sql db => delete from #db.comments as c
                                   where SQL.== (#c.comment_id,
                                                 SQL.toSQL comment_id)
                    val () = _sqlexec q conn
                  in
                    post_id
                  end)
      in
        header ("Comment " ^ Int.toString post_id ^ " deleted") ^
        "<p><a href=\"" ^ viewPostURI post_id ^ "\">\
        \View post " ^ Int.toString post_id ^ "</a></p>\n" ^
        footer ()
      end

  fun topPage () =
      header "SML# Sample Database Application" ^
      "<p><a href=\"" ^ listPostsURI () ^ "\">List of posts</a></p>\n" ^
      footer ()

  fun dispatch {method, uri, args} =
      case (method, uri) of
        ("GET",  "/") => topPage ()
      | (_,      "/") =>
        raise CGI.HTTPMethodNotAllowed ["GET","HEAD"]
      | ("GET",  "/list_posts") => listPosts ()
      | (_,      "/list_posts") =>
        raise CGI.HTTPMethodNotAllowed ["GET","HEAD"]
      | ("GET",  "/view_post") => viewPost args
      | (_,      "/view_post") =>
        raise CGI.HTTPMethodNotAllowed ["GET","HEAD"]
      | ("GET",  "/new_post") => newPost ()
      | (_,      "/new_post") =>
        raise CGI.HTTPMethodNotAllowed ["GET","HEAD"]
      | ("POST", "/do_new_post") => doNewPost args
      | (_,      "/do_new_post") =>
        raise CGI.HTTPMethodNotAllowed ["POST"]
      | ("GET",  "/edit_post") => editPost args
      | (_,      "/edit_post") =>
        raise CGI.HTTPMethodNotAllowed ["GET","HEAD"]
      | ("POST", "/do_edit_post") => doEditPost args
      | (_,      "/do_edit_post") =>
        raise CGI.HTTPMethodNotAllowed ["POST"]
      | ("GET",  "/delete_post") => deletePost args
      | (_,      "/delete_post") =>
        raise CGI.HTTPMethodNotAllowed ["GET","HEAD"]
      | ("POST", "/do_delete_post") => doDeletePost args
      | (_,      "/do_delete_post") =>
        raise CGI.HTTPMethodNotAllowed ["POST"]
      | ("POST", "/do_new_comment") => doNewComment args
      | (_,      "/do_new_comment") =>
        raise CGI.HTTPMethodNotAllowed ["POST"]
      | ("GET",  "/edit_comment") => editComment args
      | (_,      "/edit_comment") =>
        raise CGI.HTTPMethodNotAllowed ["GET","HEAD"]
      | ("POST", "/do_edit_comment") => doEditComment args
      | (_,      "/do_edit_comment") =>
        raise CGI.HTTPMethodNotAllowed ["POST"]
      | ("GET",  "/delete_comment") => deleteComment args
      | (_,      "/delete_comment") =>
        raise CGI.HTTPMethodNotAllowed ["GET","HEAD"]
      | ("POST", "/do_delete_comment") => doDeleteComment args
      | (_,      "/do_delete_comment") =>
        raise CGI.HTTPMethodNotAllowed ["POST"]
      | _ => raise CGI.HTTPNotFound

end

(*
;
print (Pages.listPosts ());
print (Pages.newPost ());
*)
