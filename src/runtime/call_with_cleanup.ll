declare i32 @sml_personality(...) nounwind

define void @sml_call_with_cleanup(
  void()* %func,
  void(i8*,i8*,i8*)* %cleanup,
  i8* %arg
) uwtable personality i32(...)* @sml_personality
{
  invoke void %func() to label %L unwind label %H
L:
  tail call void %cleanup(i8* %arg, i8* null, i8* null)
  ret void
H:
  %lpad = landingpad { i8*, i8* } cleanup
  %u = extractvalue { i8*, i8* } %lpad, 0
  %e = extractvalue { i8*, i8* } %lpad, 1
  call void %cleanup(i8* %arg, i8* %u, i8* %e)
  resume { i8*, i8* } %lpad
}
