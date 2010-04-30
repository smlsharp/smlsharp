package org.smlsharp.java2sml;

/**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: MethodInfo.java,v 1.1 2007/10/22 13:16:12 kiyoshiy Exp $
 */
class MethodInfo
{
    public String javaName_;
    public String MLName_;
    public String javaSignature_;
    public ParameterInfo params_[];
    public Class returnType_;
    public MethodInfo(String javaName,
                      String MLName,
                      String javaSignature,
                      ParameterInfo params[],
                      Class returnType)
    {
        javaName_ = javaName;
        MLName_ = MLName;
        javaSignature_ = javaSignature;
        params_ = params;
        returnType_ = returnType;
    }
}

