local
val exported = UnmanagedString.export "hogehogehogehoge"
val () = UnmanagedString.release exported
val exported = UnmanagedString.export "hoge"
in
val sz = UnmanagedString.size exported
end;