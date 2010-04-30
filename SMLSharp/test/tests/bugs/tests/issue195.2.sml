type float = real;
type pt = float * float * float;
datatype nuc_specific
  = A of pt*pt*pt*pt*pt*pt*pt*pt
  | C of pt*pt*pt*pt*pt*pt
  | G of pt*pt*pt*pt*pt*pt*pt*pt*pt
  | U of pt*pt*pt*pt*pt;
fun is_A (dgf_base_tfo,p_o3'_275_tfo,p_o3'_180_tfo,p_o3'_60_tfo,
          p,o1p,o2p,o5',c5',h5',h5'',c4',h4',o4',c1',h1',c2',h2'',o2',h2',
          c3',h3',o3',n1,n3,c2,c4,c5,c6,A _)
  = true
| is_A x = false;
