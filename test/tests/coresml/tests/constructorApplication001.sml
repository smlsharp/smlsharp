(*
constructor application expression with various argument.
rule 8

<ul>
  <li>the number of type constructor in a datatype declaration.
    <ul>
      <li>1</li>
    </ul>
  </li>
  <li>the number of data constructor in a type constructor
    <ul>
      <li>1</li>
    </ul>
  </li>
  <li>type of constructor
    <ul>
      <li>monotype</li>
      <li>polytype</li>
    </ul>
  </li>
  <li>argument expression
    <ul>
      <li>int</li>
      <li>real</li>
      <li>word</li>
      <li>char</li>
      <li>string</li>
      <li>unit</li>
      <li>record</li>
      <li>another constructor application</li>
      <li>function</li>
    </ul>
  </li>
</ul>
 *)

datatype t = D;

datatype m_int = M_INT of int;
val m_int = M_INT 1;

datatype m_real = M_REAL of real;
val m_real = M_REAL 1.23;

datatype m_word = M_WORD of word;
val m_word = M_WORD 0w3;

datatype m_char = M_CHAR of char;
val m_char = M_CHAR #"a";

datatype m_string = M_STRING of string;
val m_string = M_STRING "abc";

datatype m_unit = M_UNIT of unit;
val m_unit = M_UNIT ();

datatype m_record = M_RECORD of {x : int};
val m_record = M_RECORD {x = 999};

datatype m_constructed = M_CONSTRUCTED of t;
val m_constructed = M_CONSTRUCTED D;

datatype m_function = M_FUNCTION of int -> int;
val m_function = M_FUNCTION(fn x => x + 1);

datatype 'a p = P of 'a

val p_int = P 1;
val p_real = P 1.23;
val p_word = P 0w3;
val p_char = P #"a";
val p_string = P "abc";
val p_unit = P ();
val p_record = P {x = 111};
val p_constructed = P D;
val p_function = P (fn x => x);
