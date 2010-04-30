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
      <li>poly type</li>
    </ul>
  </li>
  <li>the number of type variables which are used to type some local variables
      as v : 'a.</li>
    <ul>
      <li>32 (safe case)</li>
      <li>33 (error case)</li>
    </ul>
  </li>
</ul>
*)
(*
(********************)
val topPoly40 =
    (
      1,2.2,3,4,5.5,6,7.7,8,9,10.10,
      11,12.12,13,14,15.15,16,17.17,18,19,20.20,
      21,22.22,23,24,25.25,26,27.27,28,29,30.30,
      31,32.32,33,34,35.35,36,37.37,38,39,40.40
    );
val topPoly40_1 = #1 topPoly40;
val topPoly40_10 = #10 topPoly40;
val topPoly40_11 = #11 topPoly40;
val topPoly40_20 = #20 topPoly40;
val topPoly40_21 = #21 topPoly40;
val topPoly40_30 = #30 topPoly40;
val topPoly40_31 = #31 topPoly40;
val topPoly40_39 = #39 topPoly40;
val topPoly40_40 = #40 topPoly40;

(********************)
val topPoly80 =
    (
      1,2.2,3,4,5.5,6,7.7,8,9,10.10,
      11,12.12,13,14,15.15,16,17.17,18,19,20.20,
      21,22.22,23,24,25.25,26,27.27,28,29,30.30,
      31,32.32,33,34,35.35,36,37.37,38,39,40.40,
      41,42.42,43,44,45.45,46,47.47,48,49,50.50,
      51,52.52,53,54,55.55,56,57.57,58,59,60.60,
      61,62.62,63,64,65.65,66,67.67,68,69,70.70,
      71,72.72,73,74,75.75,76,77.77,78,79,80.80
    );
val topPoly80_1 = #1 topPoly80;
val topPoly80_10 = #10 topPoly80;
val topPoly80_11 = #11 topPoly80;
val topPoly80_20 = #20 topPoly80;
val topPoly80_21 = #21 topPoly80;
val topPoly80_30 = #30 topPoly80;
val topPoly80_31 = #31 topPoly80;
val topPoly80_40 = #40 topPoly80;
val topPoly80_41 = #41 topPoly80;
val topPoly80_50 = #50 topPoly80;
val topPoly80_51 = #51 topPoly80;
val topPoly80_60 = #60 topPoly80;
val topPoly80_61 = #61 topPoly80;
val topPoly80_70 = #70 topPoly80;
val topPoly80_71 = #71 topPoly80;
val topPoly80_79 = #79 topPoly80;
val topPoly80_80 = #80 topPoly80;

(********************)
fun funPoly40_tv32
    (
      x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
      x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
      x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
      x31,x32,x33,x34,x35,x36,x37,x38,x39,x40
    ) =
    let
      val b =
          (
            x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
            x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
            x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
            x31,x32,
            x13,x14,x15,x16,x17,x18,x19,x20
          )
    in
      b
    end;

val rFunPoly40_tv32_1 = #1(funPoly40_tv32 topPoly40);
val rFunPoly40_tv32_10 = #10(funPoly40_tv32 topPoly40);
val rFunPoly40_tv32_11 = #11(funPoly40_tv32 topPoly40);
val rFunPoly40_tv32_20 = #20(funPoly40_tv32 topPoly40);
val rFunPoly40_tv32_21 = #21(funPoly40_tv32 topPoly40);
val rFunPoly40_tv32_30 = #30(funPoly40_tv32 topPoly40);
val rFunPoly40_tv32_31 = #31(funPoly40_tv32 topPoly40);
val rFunPoly40_tv32_39 = #39(funPoly40_tv32 topPoly40);
val rFunPoly40_tv32_40 = #40(funPoly40_tv32 topPoly40);

(********************)
fun funPoly40_tv33
    (
      x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
      x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
      x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
      x31,x32,x33,x34,x35,x36,x37,x38,x39,x40
    ) =
    let
      val b =
          (
            x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
            x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
            x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
            x31,x32,x33,
            x14,x15,x16,x17,x18,x19,x20
          )
    in
      b
    end;

val rFunPoly40_tv33_1 = #1(funPoly40_tv33 topPoly40);
val rFunPoly40_tv33_10 = #10(funPoly40_tv33 topPoly40);
val rFunPoly40_tv33_11 = #11(funPoly40_tv33 topPoly40);
val rFunPoly40_tv33_20 = #20(funPoly40_tv33 topPoly40);
val rFunPoly40_tv33_21 = #21(funPoly40_tv33 topPoly40);
val rFunPoly40_tv33_30 = #30(funPoly40_tv33 topPoly40);
val rFunPoly40_tv33_31 = #31(funPoly40_tv33 topPoly40);
val rFunPoly40_tv33_39 = #39(funPoly40_tv33 topPoly40);
val rFunPoly40_tv33_40 = #40(funPoly40_tv33 topPoly40);

(********************)
fun funPoly80_tv32
    (
      x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
      x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
      x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
      x31,x32,x33,x34,x35,x36,x37,x38,x39,x40,
      x41,x42,x43,x44,x45,x46,x47,x48,x49,x50,
      x51,x52,x53,x54,x55,x56,x57,x58,x59,x60,
      x61,x62,x63,x64,x65,x66,x67,x68,x69,x70,
      x71,x72,x73,x74,x75,x76,x77,x78,x79,x80
    ) =
    let
      val b =
          (
            x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
            x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
            x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
            x31,x32,
            x13,x14,x15,x16,x17,x18,x19,x20,
            x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
            x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
            x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
            x31,x32,
            x13,x14,x15,x16,x17,x18,x19,x20
          )
    in
      b
    end;

val rFunPoly80_tv32_1 = #1(funPoly80_tv32 topPoly80);
val rFunPoly80_tv32_10 = #10(funPoly80_tv32 topPoly80);
val rFunPoly80_tv32_11 = #11(funPoly80_tv32 topPoly80);
val rFunPoly80_tv32_20 = #20(funPoly80_tv32 topPoly80);
val rFunPoly80_tv32_21 = #21(funPoly80_tv32 topPoly80);
val rFunPoly80_tv32_30 = #30(funPoly80_tv32 topPoly80);
val rFunPoly80_tv32_31 = #31(funPoly80_tv32 topPoly80);
val rFunPoly80_tv32_40 = #40(funPoly80_tv32 topPoly80);
val rFunPoly80_tv32_41 = #41(funPoly80_tv32 topPoly80);
val rFunPoly80_tv32_50 = #50(funPoly80_tv32 topPoly80);
val rFunPoly80_tv32_51 = #51(funPoly80_tv32 topPoly80);
val rFunPoly80_tv32_60 = #60(funPoly80_tv32 topPoly80);
val rFunPoly80_tv32_61 = #61(funPoly80_tv32 topPoly80);
val rFunPoly80_tv32_70 = #70(funPoly80_tv32 topPoly80);
val rFunPoly80_tv32_71 = #71(funPoly80_tv32 topPoly80);
val rFunPoly80_tv32_79 = #79(funPoly80_tv32 topPoly80);
val rFunPoly80_tv32_80 = #80(funPoly80_tv32 topPoly80);

(********************)
fun funPoly80_tv33
    (
      x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
      x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
      x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
      x31,x32,x33,x34,x35,x36,x37,x38,x39,x40,
      x41,x42,x43,x44,x45,x46,x47,x48,x49,x50,
      x51,x52,x53,x54,x55,x56,x57,x58,x59,x60,
      x61,x62,x63,x64,x65,x66,x67,x68,x69,x70,
      x71,x72,x73,x74,x75,x76,x77,x78,x79,x80
    ) =
    let
      val b =
          (
            x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
            x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
            x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
            x31,x32,x33,
            x14,x15,x16,x17,x18,x19,x20,
            x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
            x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
            x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
            x31,x32,x33,
            x14,x15,x16,x17,x18,x19,x20
          )
    in
      b
    end;

val rFunPoly80_tv33_1 = #1(funPoly80_tv33 topPoly80);
val rFunPoly80_tv33_10 = #10(funPoly80_tv33 topPoly80);
val rFunPoly80_tv33_11 = #11(funPoly80_tv33 topPoly80);
val rFunPoly80_tv33_20 = #20(funPoly80_tv33 topPoly80);
val rFunPoly80_tv33_21 = #21(funPoly80_tv33 topPoly80);
val rFunPoly80_tv33_30 = #30(funPoly80_tv33 topPoly80);
val rFunPoly80_tv33_31 = #31(funPoly80_tv33 topPoly80);
val rFunPoly80_tv33_40 = #40(funPoly80_tv33 topPoly80);
val rFunPoly80_tv33_41 = #41(funPoly80_tv33 topPoly80);
val rFunPoly80_tv33_50 = #50(funPoly80_tv33 topPoly80);
val rFunPoly80_tv33_51 = #51(funPoly80_tv33 topPoly80);
val rFunPoly80_tv33_60 = #60(funPoly80_tv33 topPoly80);
val rFunPoly80_tv33_61 = #61(funPoly80_tv33 topPoly80);
val rFunPoly80_tv33_70 = #70(funPoly80_tv33 topPoly80);
val rFunPoly80_tv33_71 = #71(funPoly80_tv33 topPoly80);
val rFunPoly80_tv33_79 = #79(funPoly80_tv33 topPoly80);
val rFunPoly80_tv33_80 = #80(funPoly80_tv33 topPoly80);

(********************)
fun ENVPoly40_tv32
    (
      x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
      x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
      x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
      x31,x32,x33,x34,x35,x36,x37,x38,x39,x40
    ) =
    let
      fun inner (x : string) =
          (
            x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
            x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
            x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
            x31,x32,
            x13,x14,x15,x16,x17,x18,x19,x20
          )
    in
      inner
    end;

val rENVPoly40_tv32_1 = #1(ENVPoly40_tv32 topPoly40 "1");
val rENVPoly40_tv32_10 = #10(ENVPoly40_tv32 topPoly40 "10");
val rENVPoly40_tv32_11 = #11(ENVPoly40_tv32 topPoly40 "11");
val rENVPoly40_tv32_20 = #20(ENVPoly40_tv32 topPoly40 "20");
val rENVPoly40_tv32_21 = #21(ENVPoly40_tv32 topPoly40 "21");
val rENVPoly40_tv32_30 = #30(ENVPoly40_tv32 topPoly40 "30");
val rENVPoly40_tv32_31 = #31(ENVPoly40_tv32 topPoly40 "31");
val rENVPoly40_tv32_39 = #39(ENVPoly40_tv32 topPoly40 "39");
val rENVPoly40_tv32_40 = #40(ENVPoly40_tv32 topPoly40 "40");

(********************)
fun ENVPoly40_tv33
    (
      x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
      x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
      x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
      x31,x32,x33,x34,x35,x36,x37,x38,x39,x40
    ) =
    let
      fun inner (x : string) =
          (
            x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
            x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
            x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
            x31,x32,x33,
            x14,x15,x16,x17,x18,x19,x20
          )
    in
      inner
    end;

val rENVPoly40_tv33_1 = #1(ENVPoly40_tv33 topPoly40 "1");
val rENVPoly40_tv33_10 = #10(ENVPoly40_tv33 topPoly40 "10");
val rENVPoly40_tv33_11 = #11(ENVPoly40_tv33 topPoly40 "11");
val rENVPoly40_tv33_20 = #20(ENVPoly40_tv33 topPoly40 "20");
val rENVPoly40_tv33_21 = #21(ENVPoly40_tv33 topPoly40 "21");
val rENVPoly40_tv33_30 = #30(ENVPoly40_tv33 topPoly40 "30");
val rENVPoly40_tv33_31 = #31(ENVPoly40_tv33 topPoly40 "31");
val rENVPoly40_tv33_39 = #39(ENVPoly40_tv33 topPoly40 "39");
val rENVPoly40_tv33_40 = #40(ENVPoly40_tv33 topPoly40 "40");

(********************)
fun ENVPoly80_tv32
    (
      x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
      x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
      x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
      x31,x32,x33,x34,x35,x36,x37,x38,x39,x40,
      x41,x42,x43,x44,x45,x46,x47,x48,x49,x50,
      x51,x52,x53,x54,x55,x56,x57,x58,x59,x60,
      x61,x62,x63,x64,x65,x66,x67,x68,x69,x70,
      x71,x72,x73,x74,x75,x76,x77,x78,x79,x80
    ) =
    let
      fun inner (x : string) =
          (
            x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
            x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
            x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
            x31,x32,
            x13,x14,x15,x16,x17,x18,x19,x20,
            x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
            x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
            x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
            x31,x32,
            x13,x14,x15,x16,x17,x18,x19,x20
          )
    in
      inner
    end;

val rENVPoly80_tv32_1 = #1(ENVPoly80_tv32 topPoly80 "1");
val rENVPoly80_tv32_10 = #10(ENVPoly80_tv32 topPoly80 "10");
val rENVPoly80_tv32_11 = #11(ENVPoly80_tv32 topPoly80 "11");
val rENVPoly80_tv32_20 = #20(ENVPoly80_tv32 topPoly80 "20");
val rENVPoly80_tv32_21 = #21(ENVPoly80_tv32 topPoly80 "21");
val rENVPoly80_tv32_30 = #30(ENVPoly80_tv32 topPoly80 "30");
val rENVPoly80_tv32_31 = #31(ENVPoly80_tv32 topPoly80 "31");
val rENVPoly80_tv32_40 = #40(ENVPoly80_tv32 topPoly80 "40");
val rENVPoly80_tv32_41 = #41(ENVPoly80_tv32 topPoly80 "41");
val rENVPoly80_tv32_50 = #50(ENVPoly80_tv32 topPoly80 "50");
val rENVPoly80_tv32_51 = #51(ENVPoly80_tv32 topPoly80 "51");
val rENVPoly80_tv32_60 = #60(ENVPoly80_tv32 topPoly80 "60");
val rENVPoly80_tv32_61 = #61(ENVPoly80_tv32 topPoly80 "61");
val rENVPoly80_tv32_70 = #70(ENVPoly80_tv32 topPoly80 "70");
val rENVPoly80_tv32_71 = #71(ENVPoly80_tv32 topPoly80 "71");
val rENVPoly80_tv32_79 = #79(ENVPoly80_tv32 topPoly80 "79");
val rENVPoly80_tv32_80 = #80(ENVPoly80_tv32 topPoly80 "80");

(********************)
fun ENVPoly80_tv33
    (
      x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
      x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
      x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
      x31,x32,x33,x34,x35,x36,x37,x38,x39,x40,
      x41,x42,x43,x44,x45,x46,x47,x48,x49,x50,
      x51,x52,x53,x54,x55,x56,x57,x58,x59,x60,
      x61,x62,x63,x64,x65,x66,x67,x68,x69,x70,
      x71,x72,x73,x74,x75,x76,x77,x78,x79,x80
    ) =
    let
      fun inner (x : string) =
          (
            x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
            x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
            x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
            x31,x32,x33,
            x14,x15,x16,x17,x18,x19,x20,
            x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,
            x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,
            x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,
            x31,x32,x33,
            x14,x15,x16,x17,x18,x19,x20
          )
    in
      inner
    end;

val rENVPoly80_tv33_1 = #1(ENVPoly80_tv33 topPoly80 "1");
val rENVPoly80_tv33_10 = #10(ENVPoly80_tv33 topPoly80 "10");
val rENVPoly80_tv33_11 = #11(ENVPoly80_tv33 topPoly80 "11");
val rENVPoly80_tv33_20 = #20(ENVPoly80_tv33 topPoly80 "20");
val rENVPoly80_tv33_21 = #21(ENVPoly80_tv33 topPoly80 "21");
val rENVPoly80_tv33_30 = #30(ENVPoly80_tv33 topPoly80 "30");
val rENVPoly80_tv33_31 = #31(ENVPoly80_tv33 topPoly80 "31");
val rENVPoly80_tv33_40 = #40(ENVPoly80_tv33 topPoly80 "40");
val rENVPoly80_tv33_41 = #41(ENVPoly80_tv33 topPoly80 "41");
val rENVPoly80_tv33_50 = #50(ENVPoly80_tv33 topPoly80 "50");
val rENVPoly80_tv33_51 = #51(ENVPoly80_tv33 topPoly80 "51");
val rENVPoly80_tv33_60 = #60(ENVPoly80_tv33 topPoly80 "60");
val rENVPoly80_tv33_61 = #61(ENVPoly80_tv33 topPoly80 "61");
val rENVPoly80_tv33_70 = #70(ENVPoly80_tv33 topPoly80 "70");
val rENVPoly80_tv33_71 = #71(ENVPoly80_tv33 topPoly80 "71");
val rENVPoly80_tv33_79 = #79(ENVPoly80_tv33 topPoly80 "79");
val rENVPoly80_tv33_80 = #80(ENVPoly80_tv33 topPoly80 "80");

*)