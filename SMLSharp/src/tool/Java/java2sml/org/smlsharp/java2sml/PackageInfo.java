package org.smlsharp.java2sml;

import java.util.List;
import java.util.TreeMap;

/**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PackageInfo.java,v 1.1 2007/11/03 08:15:45 kiyoshiy Exp $
 */
class PackageInfo
{
    public String name_;
    public String MLName_;
    public TreeMap packageInfos_;
    public TreeMap classInfos_;

    public PackageInfo(String name,
                       String MLName,
                       TreeMap packageInfos,
                       TreeMap classInfos)
    {
        name_ = name;
        MLName_ = MLName;
        packageInfos_ = packageInfos;
        classInfos_ = classInfos;
    }
}

