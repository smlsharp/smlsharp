(**
 * @copyright (c) 2016- Tohoku University.
 * @author Atsushi Ohori
 * @author Daisuke Kikuchi
 *)
structure YAJL =
struct

  type yajl_handle = unit ptr
  type yajl_status = int
  type size_t = int64
  type 'a ctx = 'a

  val size_tToInt = Int64.toInt
  val intToSize_t = Int64.fromInt

  val ('a#boxed) yajl_alloc =
      _import "yajl_alloc"
      : (
          {
           1_yajl_null: ('a ctx) -> int,
           2_yajl_boolean: ('a ctx, int) -> int,
           3_yajl_integer: ('a ctx, int64) -> int,
           4_yajl_double: ('a ctx, real) -> int,
           5_yajl_number: unit ptr,
           6_yajl_string: ('a ctx, char ptr, size_t) -> int,
           7_yajl_start_map: ('a ctx) -> int,
           8_yajl_map_key: ('a ctx, char ptr, size_t) -> int,
           9_yajl_end_map: ('a ctx) -> int,
           10_yajl_start_array: ('a ctx) -> int,
           11_yajl_end_array: ('a ctx) -> int
          },
          unit ptr,
          'a ctx
        ) -> yajl_handle

  val yajl_parse =
      _import "yajl_parse"
      : (yajl_handle, string, size_t) -> yajl_status

  val yajl_complete_parse =
      _import "yajl_complete_parse"
      : yajl_handle -> yajl_status

  val yajl_free =
      _import "yajl_free"
      : yajl_handle -> unit ptr 

(*
     *  get an error string describing the state of the
     *  parse.
     *
     *  If verbose is non-zero, the message will include the JSON
     *  text where the error occured, along with an arrow pointing to
     *  the specific char.
     *
     *  \returns A dynamically allocated string will be returned which should
     *  be freed with yajl_free_error
     *
    YAJL_API unsigned char * yajl_get_error(yajl_handle hand, int verbose,
                                            const unsigned char * jsonText,
                                            size_t jsonTextLength);
*)
  val yajl_get_error =
      _import "yajl_get_error"
     : (yajl_handle, int, string, size_t) -> char ptr

(*
    ** free an error returned from yajl_get_error *
    YAJL_API void yajl_free_error(yajl_handle hand, unsigned char * str);
*)
  val yajl_free_error = _import "yajl_free_error" : (yajl_handle, char ptr) -> int
end
