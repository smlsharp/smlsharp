fun library s = "/usr/local/sml/smlnj-lib/" ^ s;

app use (map library [
    "lib-base-sig.sml",		"lib-base.sml",
    "random-sig.sml",		"random.sml",
    "charset-sig.sml",		"charset.sml",
    "ctype-sig.sml",		"ctype.sml",
    "string-util-sig.sml",	"string-util.sml",
    "makestring-sig.sml",	"makestring.sml",
    "string-cvt-sig.sml",	"string-cvt.sml",
    "format-sig.sml",		"format.sml"
  ]);

app use [
    "vector-sig.sml",
    "space.sml",
    "load.sml",
    "grav.sml",
    "getparam.sml",
    "data-io.sml",
    "main.sml",
    "vector2.sml",
    "vector3.sml"
  ];
