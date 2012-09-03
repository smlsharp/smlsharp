val user32 = DynamicLink.dlopen "user32.dll";
val MessageBoxA =
    DynamicLink.dlsym (user32, "MessageBoxA")
    : _import _stdcall (unit ptr, string, string, Word32.word) -> int;
val MB_SYSTEMMODAL = 0w4096;

MessageBoxA (NULL, "Hello World !", "SMLSharp", MB_SYSTEMMODAL);
