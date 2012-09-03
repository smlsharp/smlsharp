package org.smlsharp.java2sml;

/**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: FieldInfo.java,v 1.2 2007/11/01 01:51:50 kiyoshiy Exp $
 */
class FieldInfo
{
    public String javaName_;
    public String MLName_;
    public String getterMLName_;
    public String setterMLName_;
    public String javaSignature_;
    public Class type_;
    public boolean isFinal_;
    public FieldInfo(String javaName,
                     String MLName,
                     String getterMLName,
                     String setterMLName,
                     String javaSignature,
                     Class type,
                     boolean isFinal)
    {
        javaName_ = javaName;
        MLName_ = MLName;
        getterMLName_ = getterMLName;
        setterMLName_ = setterMLName;
        javaSignature_ = javaSignature;
        type_ = type;
        isFinal_ = isFinal;
    }
}

