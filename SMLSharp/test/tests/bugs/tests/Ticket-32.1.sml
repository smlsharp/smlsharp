local
val exported = UnmanagedString.export "hoge"
in
val imported = UnmanagedString.import exported
end;

