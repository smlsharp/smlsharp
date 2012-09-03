package org.smlsharp.java2sml;

import java.lang.reflect.AccessibleObject;

/**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: NonsupportedMemberException.java,v 1.1 2007/10/22 13:16:12 kiyoshiy Exp $
 */
class NonsupportedMemberException extends Exception
{
    public NonsupportedMemberException(String message){
        super(message);
    }
    public NonsupportedMemberException(AccessibleObject member){
        super("not supported member: " + member.toString());
    }
}

