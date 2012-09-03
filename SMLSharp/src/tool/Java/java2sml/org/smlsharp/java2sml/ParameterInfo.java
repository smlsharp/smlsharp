package org.smlsharp.java2sml;

/**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ParameterInfo.java,v 1.1 2007/10/22 13:16:12 kiyoshiy Exp $
 */
class ParameterInfo
{
    public String name_;
    public Class type_;
    public ParameterInfo(String name, Class type){
        name_ = name;
        type_ = type;
    }
}

