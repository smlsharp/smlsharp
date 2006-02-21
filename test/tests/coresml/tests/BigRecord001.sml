(*
creation of a record block which has many fields.
<ul>
  <li>kind of record
     <ul>
       <li>top level record</li>
       <li>a record built in a function</li>
       <li>an ENV block which contains free variables in a function</li>
     </ul>
  </li>
  <li>type of record</li>
    <ul>
      <li>mono type</li>
    </ul>
  </li>
</ul>
*)
(*
type rec40 =
     int * real * int * int * real * int * real * int * int * real
     * int * real * int * int * real * int * real * int * int * real
     * int * real * int * int * real * int * real * int * int * real
     * int * real * int * int * real * int * real * int * int * real;

type rec80 =
     int * real * int * int * real * int * real * int * int * real
     * int * real * int * int * real * int * real * int * int * real
     * int * real * int * int * real * int * real * int * int * real
     * int * real * int * int * real * int * real * int * int * real
     * int * real * int * int * real * int * real * int * int * real
     * int * real * int * int * real * int * real * int * int * real
     * int * real * int * int * real * int * real * int * int * real
     * int * real * int * int * real * int * real * int * int * real;

(********************)
val topMono40 =
    (
      1,2.2,3,4,5.5,6,7.7,8,9,10.10,
      11,12.12,13,14,15.15,16,17.17,18,19,20.20,
      21,22.22,23,24,25.25,26,27.27,28,29,30.30,
      31,32.32,33,34,35.35,36,37.37,38,39,40.40
    ) : rec40;
val topMono40_1 = #1 topMono40;
val topMono40_10 = #10 topMono40;
val topMono40_11 = #11 topMono40;
val topMono40_20 = #20 topMono40;
val topMono40_21 = #21 topMono40;
val topMono40_30 = #30 topMono40;
val topMono40_31 = #31 topMono40;
val topMono40_39 = #39 topMono40;
val topMono40_40 = #40 topMono40;

(********************)
val topMono80 =
    (
      1,2.2,3,4,5.5,6,7.7,8,9,10.10,
      11,12.12,13,14,15.15,16,17.17,18,19,20.20,
      21,22.22,23,24,25.25,26,27.27,28,29,30.30,
      31,32.32,33,34,35.35,36,37.37,38,39,40.40,
      41,42.42,43,44,45.45,46,47.47,48,49,50.50,
      51,52.52,53,54,55.55,56,57.57,58,59,60.60,
      61,62.62,63,64,65.65,66,67.67,68,69,70.70,
      71,72.72,73,74,75.75,76,77.77,78,79,80.80
    ) : rec80;
val topMono80_1 = #1 topMono80;
val topMono80_10 = #10 topMono80;
val topMono80_11 = #11 topMono80;
val topMono80_20 = #20 topMono80;
val topMono80_21 = #21 topMono80;
val topMono80_30 = #30 topMono80;
val topMono80_31 = #31 topMono80;
val topMono80_40 = #40 topMono80;
val topMono80_41 = #41 topMono80;
val topMono80_50 = #50 topMono80;
val topMono80_51 = #51 topMono80;
val topMono80_60 = #60 topMono80;
val topMono80_61 = #61 topMono80;
val topMono80_70 = #70 topMono80;
val topMono80_71 = #71 topMono80;
val topMono80_79 = #79 topMono80;
val topMono80_80 = #80 topMono80;

(********************)
fun funMono40
    ((
       x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
       x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
       x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
       x31,x32,x33,x34,x35,x36,x37,x38,x39,x40
     ) : rec40) =
    let
      val b =
          (
            x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
            x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
            x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
            x31,x32,x33,x34,x35,x36,x37,x38,x39,x40
          ) : rec40
    in
      b
    end;

val rFunMono40_1 = #1(funMono40 topMono40);
val rFunMono40_10 = #10(funMono40 topMono40);
val rFunMono40_11 = #11(funMono40 topMono40);
val rFunMono40_20 = #20(funMono40 topMono40);
val rFunMono40_21 = #21(funMono40 topMono40);
val rFunMono40_30 = #30(funMono40 topMono40);
val rFunMono40_31 = #31(funMono40 topMono40);
val rFunMono40_39 = #39(funMono40 topMono40);
val rFunMono40_40 = #40(funMono40 topMono40);

(********************)
fun funMono80
    ((
       x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
       x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
       x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
       x31,x32,x33,x34,x35,x36,x37,x38,x39,x40,
       x41,x42,x43,x44,x45,x46,x47,x48,x49,x50,
       x51,x52,x53,x54,x55,x56,x57,x58,x59,x60,
       x61,x62,x63,x64,x65,x66,x67,x68,x69,x70,
       x71,x72,x73,x74,x75,x76,x77,x78,x79,x80
     ) : rec80) =
    let
      val b =
          (
            x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
            x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
            x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
            x31,x32,x33,x34,x35,x36,x37,x38,x39,x40,
            x41,x42,x43,x44,x45,x46,x47,x48,x49,x50,
            x51,x52,x53,x54,x55,x56,x57,x58,x59,x60,
            x61,x62,x63,x64,x65,x66,x67,x68,x69,x70,
            x71,x72,x73,x74,x75,x76,x77,x78,x79,x80
          ) : rec80
    in
      b
    end;

val rFunMono80_1 = #1(funMono80 topMono80);
val rFunMono80_10 = #10(funMono80 topMono80);
val rFunMono80_11 = #11(funMono80 topMono80);
val rFunMono80_20 = #20(funMono80 topMono80);
val rFunMono80_21 = #21(funMono80 topMono80);
val rFunMono80_30 = #30(funMono80 topMono80);
val rFunMono80_31 = #31(funMono80 topMono80);
val rFunMono80_40 = #40(funMono80 topMono80);
val rFunMono80_41 = #41(funMono80 topMono80);
val rFunMono80_50 = #50(funMono80 topMono80);
val rFunMono80_51 = #51(funMono80 topMono80);
val rFunMono80_60 = #60(funMono80 topMono80);
val rFunMono80_61 = #61(funMono80 topMono80);
val rFunMono80_70 = #70(funMono80 topMono80);
val rFunMono80_71 = #71(funMono80 topMono80);
val rFunMono80_79 = #79(funMono80 topMono80);
val rFunMono80_80 = #80(funMono80 topMono80);

(********************)
fun ENVMono40
    ((
       x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
       x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
       x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
       x31,x32,x33,x34,x35,x36,x37,x38,x39,x40
     ) : rec40) =
    let
      fun inner x =
          (
            x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
            x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
            x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
            x31,x32,x33,x34,x35,x36,x37,x38,x39,x40
          ) : rec40
    in
      inner
    end;

val rENVMono40_1 = #1(ENVMono40 topMono40 "1");
val rENVMono40_10 = #10(ENVMono40 topMono40 "10");
val rENVMono40_11 = #11(ENVMono40 topMono40 "11");
val rENVMono40_20 = #20(ENVMono40 topMono40 "20");
val rENVMono40_21 = #21(ENVMono40 topMono40 "21");
val rENVMono40_30 = #30(ENVMono40 topMono40 "30");
val rENVMono40_31 = #31(ENVMono40 topMono40 "31");
val rENVMono40_39 = #39(ENVMono40 topMono40 "39");
val rENVMono40_40 = #40(ENVMono40 topMono40 "40");

(********************)
fun ENVMono80
    ((
       x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
       x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
       x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
       x31,x32,x33,x34,x35,x36,x37,x38,x39,x40,
       x41,x42,x43,x44,x45,x46,x47,x48,x49,x50,
       x51,x52,x53,x54,x55,x56,x57,x58,x59,x60,
       x61,x62,x63,x64,x65,x66,x67,x68,x69,x70,
       x71,x72,x73,x74,x75,x76,x77,x78,x79,x80
     ) : rec80) =
    let
      fun inner x =
          (
            x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
            x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
            x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
            x31,x32,x33,x34,x35,x36,x37,x38,x39,x40,
            x41,x42,x43,x44,x45,x46,x47,x48,x49,x50,
            x51,x52,x53,x54,x55,x56,x57,x58,x59,x60,
            x61,x62,x63,x64,x65,x66,x67,x68,x69,x70,
            x71,x72,x73,x74,x75,x76,x77,x78,x79,x80
          ) : rec80
    in
      inner
    end;

val rENVMono80_1 = #1(ENVMono80 topMono80 "1");
val rENVMono80_10 = #10(ENVMono80 topMono80 "10");
val rENVMono80_11 = #11(ENVMono80 topMono80 "11");
val rENVMono80_20 = #20(ENVMono80 topMono80 "20");
val rENVMono80_21 = #21(ENVMono80 topMono80 "21");
val rENVMono80_30 = #30(ENVMono80 topMono80 "30");
val rENVMono80_31 = #31(ENVMono80 topMono80 "31");
val rENVMono80_40 = #40(ENVMono80 topMono80 "40");
val rENVMono80_41 = #41(ENVMono80 topMono80 "41");
val rENVMono80_50 = #50(ENVMono80 topMono80 "50");
val rENVMono80_51 = #51(ENVMono80 topMono80 "51");
val rENVMono80_60 = #60(ENVMono80 topMono80 "60");
val rENVMono80_61 = #61(ENVMono80 topMono80 "61");
val rENVMono80_70 = #70(ENVMono80 topMono80 "70");
val rENVMono80_71 = #71(ENVMono80 topMono80 "71");
val rENVMono80_79 = #79(ENVMono80 topMono80 "79");
val rENVMono80_80 = #80(ENVMono80 topMono80 "80");

*)