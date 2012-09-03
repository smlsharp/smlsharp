package org.smlsharp.java2sml;

import java.lang.reflect.Method;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.SortedSet;

/**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OverloadedMethodRenamerBySignature.java,v 1.3 2010/04/23 02:40:25 kiyoshiy Exp $
 */
public class OverloadedMethodRenamerBySignature
    extends OverloadedMethodRenamer
{

    String signatureOfType(Class type)
    {
        if(type.isArray()){
            return signatureOfType(type.getComponentType()) + "s";
        }

        if(type.equals(Boolean.TYPE)){ // Z
            return "Z";
        }
        else if(type.equals(Byte.TYPE)){ // B
            return "B";
        }
        else if(type.equals(Character.TYPE)){ // C
            return "C";
        }
        else if(type.equals(Short.TYPE)){ // S
            return "S";
        }
        else if(type.equals(Integer.TYPE)){ // I
            return "I";
        }
        else if(type.equals(Long.TYPE)){ // J
            return "J";
        }
        else if(type.equals(Float.TYPE)){ // F
            return "F";
        }
        else if(type.equals(Double.TYPE)){ // D
            return "D";
        }
        else if(type.equals(Void.TYPE)){ // V
            return "V";
        }
        else{ // object
            String name[] = type.getName().split("\\.|\\$");
            return name[name.length - 1];

        }
    }

    String nameOfMethod(MethodInfo methodInfo)
    {
        String name = methodInfo.MLName_;
        if(0 == methodInfo.params_.length){return name;}
        name += "'";
        for(int i = 0; i < methodInfo.params_.length; i += 1){
            name += signatureOfType(methodInfo.params_[i].type_);
        }
        return name;
    }

    public void rename(OverloadedMap overloadedMap)
    {
        Collection methodsList = overloadedMap.getAll();
        for(Iterator i = methodsList.iterator(); i.hasNext(); ){
            SortedSet methods = (SortedSet)i.next();
            if(1 == methods.size()){continue;}
            int c = 1;
            for(Iterator j = methods.iterator(); j.hasNext(); c += 1){
                MethodInfo method = (MethodInfo)j.next();
                method.MLName_ = nameOfMethod(method);
            }
        }
    }
}
