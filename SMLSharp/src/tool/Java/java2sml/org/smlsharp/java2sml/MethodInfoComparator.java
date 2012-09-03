package org.smlsharp.java2sml;

import java.util.Comparator;

/**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: MethodInfoComparator.java,v 1.1 2007/10/22 13:16:12 kiyoshiy Exp $
 */
class MethodInfoComparator
    implements Comparator
{
    public int compare(Object o1, Object o2)
    {
        MethodInfo m1 = (MethodInfo)o1;
        MethodInfo m2 = (MethodInfo)o2;
        if(!m1.javaName_.equals(m2.javaName_)){
            return m1.javaName_.compareTo(m2.javaName_);
        }
        if(m1.params_.length != m2.params_.length){
            return
            (new Integer(m1.params_.length))
            .compareTo(new Integer(m2.params_.length));
        }
        for(int index = 0; index < m1.params_.length; index += 1){
            String p1 = m1.params_[index].type_.getName();
            String p2 = m2.params_[index].type_.getName();
            int c = p1.compareTo(p2);
            if(0 != c){return c;}
        }
        return 0;
    }
}
