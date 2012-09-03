package org.smlsharp.java2sml;

/**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: NonsupportedTypeException.java,v 1.1 2007/10/22 13:16:12 kiyoshiy Exp $
 */
class NonsupportedTypeException extends NonsupportedMemberException
{
    public NonsupportedTypeException(Class type){
        super(type.toString() + " is not supported.");
    }
}

