package org.smlsharp.java2sml;

import java.util.List;

/**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ClassInfo.java,v 1.5 2007/11/23 07:57:12 kiyoshiy Exp $
 */
class ClassInfo
{
    public Class clazz_;
    public ClassInfo[] classes_;
    public String MLName_;
    public List constructorInfos_;
    public List staticMethodInfos_;
    public List methodInfos_;
    public List staticFieldInfos_;
    public List fieldInfos_;
    public List translationErrors_;

    public ClassInfo(Class clazz,
                     String MLName,
                     ClassInfo[] classes,
                     List constructorInfos,
                     List staticMethodInfos,
                     List methodInfos,
                     List staticFieldInfos,
                     List fieldInfos,
                     List translationErrors)
    {
        clazz_ = clazz;
        MLName_ = MLName;
        classes_ = classes;
        constructorInfos_ = constructorInfos;
        staticMethodInfos_ = staticMethodInfos;
        methodInfos_ = methodInfos;
        staticFieldInfos_ = staticFieldInfos;
        fieldInfos_ = fieldInfos;
        translationErrors_ = translationErrors;
    }
}
