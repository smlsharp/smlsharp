package org.smlsharp.java2sml;

import java.lang.reflect.Method;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.SortedSet;

/**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OverloadedMethodRenamerByIndex.java,v 1.2 2010/04/23 02:40:25 kiyoshiy Exp $
 */
public class OverloadedMethodRenamerByIndex
    extends OverloadedMethodRenamer
{
    public void rename(OverloadedMap overloadedMap)
    {
        Collection methodsList = overloadedMap.getAll();
        for(Iterator i = methodsList.iterator(); i.hasNext(); ){
            SortedSet methods = (SortedSet)i.next();
            if(1 == methods.size()){continue;}
            int c = 1;
            for(Iterator j = methods.iterator(); j.hasNext(); c += 1){
                MethodInfo method = (MethodInfo)j.next();
                if(0 == method.params_.length){c -= 1; continue;}
                method.MLName_ = method.MLName_ + "'" + c;
            }
        }
    }
    
}
