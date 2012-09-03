datatype t = X of real ref;
val r = ref 1.0;
X r = X r;
