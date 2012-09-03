package org.smlsharp.java2sml;

/**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ConstructorInfo.java,v 1.2 2010/04/23 02:40:24 kiyoshiy Exp $
 */
class ConstructorInfo
    extends MethodInfo
{
    public ConstructorInfo(String MLName,
                           String javaSignature,
                           ParameterInfo params[],
                           Class clazz)
    {
        super("new", MLName, javaSignature, params, clazz);
    }
}

