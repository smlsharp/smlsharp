fun id x = x;
val fHanldePolyBodyPolyVar = id handle _ => id;
val xHanldePolyBodyPolyVar = fHanldePolyBodyPolyVar 2;

