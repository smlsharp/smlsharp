package org.smlsharp.java2sml;

import java.util.Collection;
import java.util.Iterator;
import java.util.TreeMap;
import java.util.TreeSet;

/**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OverloadedMap.java,v 1.2 2007/11/20 04:46:44 kiyoshiy Exp $
 */
class OverloadedMap
{
    private TreeMap map_ = new TreeMap();
    public OverloadedMap(){}
    public OverloadedMap(MethodInfo[] methodInfos)
    {
        for(int index = 0; index < methodInfos.length; index += 1){
            put(methodInfos[index]);
        }
    }
    public OverloadedMap(Collection methodInfos)
    {
        for(Iterator i = methodInfos.iterator(); i.hasNext(); ){
            put((MethodInfo)i.next());
        }
    }
    public void put(MethodInfo method)
    {
        // NOTE: Methods are sort by MLName, not by javaName.
        TreeSet overloads = (TreeSet)map_.get(method.MLName_);
        if(null == overloads){
            overloads = new TreeSet(new MethodInfoComparator());
            map_.put(method.MLName_, overloads);
        }
        overloads.add(method);
    }
    public Collection getAll()
    {
        return map_.values();
    }
}

