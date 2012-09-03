package org.smlsharp.java2sml;

import java.util.Comparator;

/**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ClassComparator.java,v 1.1 2007/11/19 05:27:08 kiyoshiy Exp $
 */
class ClassComparator
    implements Comparator
{
    public int compare(Object o1, Object o2)
    {
        Class c1 = (Class)o1;
        Class c2 = (Class)o2;
        return c1.getName().compareTo(c2.getName());
    }
}
