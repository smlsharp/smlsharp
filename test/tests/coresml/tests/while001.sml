(*
while expression.

<ul>
  <li>the number of repetition
    <ul>
      <li>more than 0</li>
      <li>0</li>
    </ul>
  </li>
</ul>
 *)
val counter = ref 0;
val buffer = ref ([] : int list);
while (!counter < 10)
do (counter := (!counter) + 1; buffer := (!counter) :: (!buffer));
val result = !buffer;

while false do print "ERROR";
