package org.smlsharp.java2sml;

import java.lang.reflect.AccessibleObject;
import java.lang.reflect.Constructor;
import java.lang.reflect.Method;
import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.util.Collection;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.SortedSet;

/**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ClassTranslator.java,v 1.10 2010/04/25 07:46:59 kiyoshiy Exp $
 */
class ClassTranslator
{

    boolean isSupportedType(Class type)
    {
        return true;
    }

    boolean isSupportedReturnType(Class type)
    {
        // FIXME: remove following 2 lines when FFI supports float and int64.
        if(Float.TYPE.equals(type)){return false;}
        if(Long.TYPE.equals(type)){return false;}

        return isSupportedType(type);
    }

    String signatureOfType(Class type)
    {
        if(type.isArray()){
            return "[" + signatureOfType(type.getComponentType());
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
            return "L" + type.getName().replace('.', '/') + ";";
        }
    }

    String signatureOfMethod(Class javaParams[], Class returnType)
    {
        StringBuffer buffer = new StringBuffer("(");
        for(int index = 0; index < javaParams.length; index += 1){
            buffer.append(signatureOfType(javaParams[index]));
        }
        buffer.append(")");
        buffer.append(signatureOfType(returnType));
        return buffer.toString();
    }

    MethodInfo translateMethod(Method method)
        throws NonsupportedMemberException
    {
        Class javaParams[] = method.getParameterTypes();
        ParameterInfo MLParams[] = new ParameterInfo[javaParams.length];
        for(int index = 0; index < javaParams.length; index += 1){
            String name = "arg" + index;
            Class param = javaParams[index];
            if(!isSupportedType(param)){
                throw new NonsupportedMemberException(method);
            }
            MLParams[index] = new ParameterInfo(name, param);
        }
        String name = method.getName();
        String MLName = name; // MLName is fixed later.
        Class returnType = method.getReturnType();
        if(!isSupportedReturnType(returnType)){
            throw new NonsupportedMemberException(method);
        }
        String signature = 
        signatureOfMethod(method.getParameterTypes(), method.getReturnType());
        MethodInfo methodInfo =
            new MethodInfo(name, MLName, signature, MLParams, returnType);
        return methodInfo;
    }

    ConstructorInfo translateConstructor(Constructor constructor)
        throws NonsupportedMemberException
    {
        Class javaParams[] = constructor.getParameterTypes();
        ParameterInfo MLParams[] = new ParameterInfo[javaParams.length];
        for(int index = 0; index < javaParams.length; index += 1){
            String name = "arg" + index;
            Class param = javaParams[index];
            if(!isSupportedType(param)){
                throw new NonsupportedMemberException(constructor);
            }
            MLParams[index] = new ParameterInfo(name, param);
        }
        String MLName = "new";
        String signature =
        signatureOfMethod(constructor.getParameterTypes(), Void.TYPE);
        Class clazz = constructor.getDeclaringClass();
        ConstructorInfo constructorInfo =
        new ConstructorInfo(MLName, signature, MLParams, clazz);

        return constructorInfo;
    }

    FieldInfo translateField(Field field)
        throws NonsupportedMemberException
    {
        String name = field.getName();
        Class type = field.getType();
        if(!isSupportedType(type)){
            throw new NonsupportedMemberException(field);
        }
        String signature = signatureOfType(field.getType());
        boolean isFinal = 0 != (Modifier.FINAL & field.getModifiers());
        String MLName = name;
        String getterMLName =
            isSupportedReturnType(type) ? ("get'" + MLName) : null;
        String setterMLName = isFinal ? null : ("set'" + MLName);
        FieldInfo fieldInfo = new FieldInfo(name,
                                            MLName,
                                            getterMLName,
                                            setterMLName,
                                            signature,
                                            type,
                                            isFinal);
        return fieldInfo;
    }

    String getMLClassName(Class clazz)
    {
        if(clazz.isArray() || clazz.isPrimitive()){
            throw
            new IllegalArgumentException("cannot generate code for " + clazz);
        }
        String[] FQN = clazz.getName().split("\\.");
        if(null == clazz.getDeclaringClass()){
            return FQN[FQN.length - 1];
        }

        /* clazz is a member class of another class.
         * see http://java.sun.com/docs/books/jls/third_edition/html/binaryComp.html#44909
         */
        String lastName = FQN[FQN.length - 1];
        return lastName.substring(lastName.lastIndexOf('$') + 1);
    }

    ClassInfo translateClass(Class clazz)
    {
        LinkedList errors = new LinkedList();

        String MLName = getMLClassName(clazz);

        Class[] classes = clazz.getClasses();
        ClassInfo[] classInfos = new ClassInfo[classes.length];
        for(int index = 0; index < classes.length; index += 1){
            classInfos[index] = translateClass(classes[index]);
        }
        
        Method methods[] = clazz.getMethods();
        LinkedList methodInfos = new LinkedList();
        LinkedList staticMethodInfos = new LinkedList();
        LinkedList allMethodInfos = new LinkedList();
        for(int index = 0; index < methods.length; index += 1){
            try{
                Method method = methods[index];
                MethodInfo methodInfo = translateMethod(method);
                if(0 == (Modifier.STATIC & method.getModifiers())){
                    methodInfos.add(methodInfo);
                }
                else{
                    staticMethodInfos.add(methodInfo);
                }
                allMethodInfos.add(methodInfo);
            }
            catch(NonsupportedMemberException e){
                errors.add(e);
            }
        }
        new OverloadedMethodRenamerBySignature().rename(new OverloadedMap(allMethodInfos));
        new OverloadedMethodRenamerByIndex().rename(new OverloadedMap(allMethodInfos));

        Constructor constructors[] = clazz.getConstructors();
        LinkedList constructorInfos = new LinkedList();
        for(int index = 0; index < constructors.length; index += 1){
            try{
                Constructor constructor = constructors[index];
                ConstructorInfo constructorInfo =
                    translateConstructor(constructor);
                constructorInfos.add(constructorInfo);
            }
            catch(NonsupportedMemberException e){
                errors.add(e);
            }
        }
        new OverloadedMethodRenamerBySignature().rename(new OverloadedMap(constructorInfos));
        new OverloadedMethodRenamerByIndex().rename(new OverloadedMap(constructorInfos));

        Field fields[] = clazz.getFields();
        LinkedList fieldInfos = new LinkedList();
        LinkedList staticFieldInfos = new LinkedList();
        for(int index = 0; index < fields.length; index += 1){
            try{
                Field field = fields[index];
                FieldInfo fieldInfo = translateField(field);
                if(0 == (Modifier.STATIC & field.getModifiers())){
                    fieldInfos.add(fieldInfo);
                }
                else{
                    staticFieldInfos.add(fieldInfo);
                }
            }
            catch(NonsupportedMemberException e){
                errors.add(e);
            }
        }

        ClassInfo info = new ClassInfo(clazz,
                                       MLName,
                                       classInfos,
                                       constructorInfos,
                                       staticMethodInfos,
                                       methodInfos,
                                       staticFieldInfos,
                                       fieldInfos,
                                       errors);

        return info;
    }
    
}
