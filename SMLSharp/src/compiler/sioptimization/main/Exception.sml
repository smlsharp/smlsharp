(**
 * @copyright (c) 2006, Tohoku University.
 * @author Yutaka Matsuno
 * @version $Id: Exception.sml,v 1.4 2007/09/20 09:02:54 matsu Exp $
 *)


structure ExceptionAnalysis = struct     
    
structure SI = SymbolicInstructions
structure AUX = Aux
                

    
fun getHandlerLabel prog = let fun aux (ins,R) = case ins of SI.PushHandler {handlerStart, ...} => 
                                                             AUX.ad_set.add (R,handlerStart)
                                                           | _ => R
                           in Vector.foldl aux AUX.ad_set.empty prog
                           end

                           
fun getHandlerNumber prog = let val h_lb = getHandlerLabel prog
                                fun aux (i,ins,R) = case ins of SI.Label ad => 
                                                                if AUX.ad_set.member (h_lb,ad)
                                                                then AUX.ad_map.insert(R,ad,i)
                                                                else R
                                                              | _ => R
                            in Vector.foldli aux AUX.ad_map.empty (prog(*,0,NONE*))
                            end
                            


fun makeExceptionRegion prog = let val handler_ns = getHandlerNumber prog
                                   val l_prog = Vector.foldri (fn (i,ins,R) => (i,ins) :: R) [] (prog(*,0,NONE*))  
                                   fun aux p r_map region h_map = 
                                       case p of [] => (IntBinaryMap.map AUX.ad_set.listItems r_map,h_map)
                                               | (l,SI.PopHandler {guardedStart}) :: t => 
                                                 let val new_region = AUX.ad_set.add (region,guardedStart)
                                                 in aux t (IntBinaryMap.insert (r_map,l,new_region)) 
                                                        new_region h_map
                                                 end 
                                               | (l2, SI.PushHandler {handlerStart,... }) :: (h2 as (_,SI.Label lb)) :: t => 
                                                 let val new_region = AUX.ad_set.delete (region,lb)
                                                 in
                                                     aux (h2::t) (IntBinaryMap.insert (r_map,l2,region))  new_region 
                                                         (AUX.ad_map.insert(h_map,lb,valOf(AUX.ad_map.find(handler_ns,handlerStart)))) 
                                                 end
                                               | (l,_) :: t => 
                                                 aux t (IntBinaryMap.insert (r_map,l,region))  region h_map
                               in (aux (rev l_prog) IntBinaryMap.empty AUX.ad_set.empty AUX.ad_map.empty,
                                   IntBinarySet.addList(IntBinarySet.empty,AUX.ad_map.listItems handler_ns))
                               end
                               
                               
end 
