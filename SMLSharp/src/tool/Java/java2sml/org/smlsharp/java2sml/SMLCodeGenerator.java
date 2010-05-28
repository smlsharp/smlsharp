package org.smlsharp.java2sml;

import java.util.Collection;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;

/**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SMLCodeGenerator.java,v 1.17 2010/04/25 13:38:47 kiyoshiy Exp $
 */
class SMLCodeGenerator
{
    String getFQN(ClassInfo classInfo)
    {
        return classInfo.clazz_.getName().replace('.', '/');
    }

    String FQNToFieldLabel(String FQN)
    {
        return FQN.replace('.', '\'').replace('$', '\'');
    }

    void collectSuperClasses(Set classes, Class clazz)
    {
        classes.add(clazz);
        if(Object.class.equals(clazz)){return;}
        if(null != clazz.getSuperclass()){
            collectSuperClasses(classes, clazz.getSuperclass());
        }
        Class interfaces[] = clazz.getInterfaces();
        for(int i = 0; i < interfaces.length; i += 1){
            collectSuperClasses(classes, interfaces[i]);
        }
    }

    String MLTypeOf(Class type)
        throws NonsupportedTypeException
    {
        if(type.isArray()){
            return "JV.Object";
        }

        if(type.equals(Boolean.TYPE)){
            return "JV.boolean";
        }
        else if(type.equals(Byte.TYPE)){
            return "JV.byte";
        }
        else if(type.equals(Character.TYPE)){
            return "JV.char";
        }
        else if(type.equals(Short.TYPE)){
            return "JV.short";
        }
        else if(type.equals(Integer.TYPE)){
            return "JV.int";
        }
        else if(type.equals(Long.TYPE)){
            return "JV.long";
        }
        else if(type.equals(Float.TYPE)){
            return "JV.float";
        }
        else if(type.equals(Double.TYPE)){
            return "JV.double";
        }
        else if(type.equals(Void.TYPE)){
            return "unit";
        }
        else if(type.equals("".getClass())){
            return "JV.String";
        }
        else{ // object
            return "JV.Object";
        }
    }

    String MLConvOf(Class type)
        throws NonsupportedTypeException
    {
        if(type.isArray()){
            return "L";
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
        else if(type.equals("".getClass())){
            return "T";
        }
        else{ // object
            return "L";
        }
    }

    String generateMethod(MethodInfo methodInfo)
        throws NonsupportedTypeException
    {
        String code = "";
        code += "  fun " + methodInfo.MLName_ + " this (";
        for(int i = 0; i < methodInfo.params_.length; i += 1){
            if(0 < i){code += ",";}
            code += methodInfo.params_[i].name_;
        }
        code += ") =\n";
        code += "      JC.method" + MLConvOf(methodInfo.returnType_) + "\n";
        code += "          (!static." + methodInfo.MLName_ + "_methodID)\n";
        code += "          this\n";
        code += "          (";
        for(int i = 0; i < methodInfo.params_.length; i += 1){
            code += "JC.arg" + MLConvOf(methodInfo.params_[i].type_) + " "
                    + methodInfo.params_[i].name_ + " :: ";
        }
        code += "[])\n";
        return code;
    }

    String generateStaticMethod(MethodInfo methodInfo)
        throws NonsupportedTypeException
    {
        String code = "";
        code += "  fun " + methodInfo.MLName_ + " (";
        for(int i = 0; i < methodInfo.params_.length; i += 1){
            if(0 < i){code += ",";}
            code += methodInfo.params_[i].name_;
        }
        code += ") =\n";
        code += "      JC.static_method" + MLConvOf(methodInfo.returnType_) + "\n";
        code += "          (!static." + methodInfo.MLName_ + "_methodID)\n";
        code += "          (static.getClass())\n";
        code += "          (";
        for(int i = 0; i < methodInfo.params_.length; i += 1){
            code += "JC.arg" + MLConvOf(methodInfo.params_[i].type_) + " "
                    + methodInfo.params_[i].name_ + " :: ";
        }
        code += "[])\n";
        return code;
    }

    String generateConstructor(ConstructorInfo constructorInfo)
        throws NonsupportedTypeException
    {
        String code = "";
        code += "  fun " + constructorInfo.MLName_ + " (";
        for(int i = 0; i < constructorInfo.params_.length; i += 1){
            if(0 < i){code += ",";}
            code += constructorInfo.params_[i].name_;
        }
        code += ") =\n";
        code += "      (JC.newInstance\n";
        code += "           (static.getClass())\n";
        code += "           VTBL\n";
        code += "           (!static." + constructorInfo.MLName_ + "_methodID)\n";
        code += "           (";
        for(int i = 0; i < constructorInfo.params_.length; i += 1){
            code += "JC.arg" + MLConvOf(constructorInfo.params_[i].type_) + " "
                    + constructorInfo.params_[i].name_ + " :: ";
        }
        code += "[]))\n";
        code += "      : instance\n";
        return code;
    }

    String generateStaticField(FieldInfo fieldInfo)
        throws NonsupportedTypeException
    {
        String code = "";
        if(null != fieldInfo.getterMLName_){
            code += "  fun " + fieldInfo.getterMLName_ + " () =\n";
            code += "      JC.getStaticField" + MLConvOf(fieldInfo.type_) + "\n";
            code += "      (!static." + fieldInfo.MLName_ + "_fieldID)\n";
            code += "      (static.getClass())\n";
        }
        if(null != fieldInfo.setterMLName_){
            code += "  fun " + fieldInfo.setterMLName_ + " arg =\n";
            code += "      JC.setStaticField" + MLConvOf(fieldInfo.type_) + "\n";
            code += "      (!static." + fieldInfo.MLName_ + "_fieldID)\n";
            code += "      (static.getClass())\n";
            code += "      arg\n";
        }
        return code;
    }

    String generateField(FieldInfo fieldInfo)
        throws NonsupportedTypeException
    {
        String code = "";
        if(null != fieldInfo.getterMLName_){
            code += "  fun " + fieldInfo.getterMLName_ + " this () =\n";
            code += "      JC.getField" + MLConvOf(fieldInfo.type_) + "\n";
            code += "      (!static." + fieldInfo.MLName_ + "_fieldID)\n";
            code += "      this\n";
        }
        if(null != fieldInfo.setterMLName_){
            code += "  fun " + fieldInfo.setterMLName_ + " this arg =\n";
            code += "      JC.setField" + MLConvOf(fieldInfo.type_) + "\n";
            code += "      (!static." + fieldInfo.MLName_ + "_fieldID)\n";
            code += "      this\n";
            code += "      arg\n";
        }
        return code;
    }

    void generateMLTypeOfMethod(List recordFields, MethodInfo methodInfo)
        throws NonsupportedTypeException
    {
        String code = "";
        code += methodInfo.MLName_ + " : ";
        code += "JV.Object -> ";
        if(0 == methodInfo.params_.length){
            code += "unit";
        }
        else{
            code += "(";
            for(int i = 0; i < methodInfo.params_.length; i += 1){
                if(0 < i){code += " * ";}
                code += MLTypeOf(methodInfo.params_[i].type_);
            }
            code += ")";
        }
        code += " -> " + MLTypeOf(methodInfo.returnType_);

        recordFields.add(code);
    }

    void generateMLTypeOfField(List recordFields, FieldInfo fieldInfo)
        throws NonsupportedTypeException
    {
        if(null != fieldInfo.getterMLName_){
            recordFields.add(fieldInfo.getterMLName_ + " : "
                             + "JV.Object -> unit -> "
                             + MLTypeOf(fieldInfo.type_));
        }
        if(null != fieldInfo.setterMLName_){
            recordFields.add(fieldInfo.setterMLName_ + " : "
                             + "JV.Object -> "
                             + MLTypeOf(fieldInfo.type_) + " -> unit");
        }
    }

    String generateClass(ClassInfo classInfo)
        throws NonsupportedTypeException
    {
        String code = "";

        String structureName = classInfo.MLName_;
        code += "structure " + structureName + " = \n";
        code += "struct\n";

        // member classes
        for(int index = 0; index < classInfo.classes_.length; index += 1){
            code += generateClass(classInfo.classes_[index]);
        }

        // errors
        code += "  (*\n";
        code += "    Errors:\n";
        for(Iterator i = classInfo.translationErrors_.iterator(); i.hasNext();)
        {
            code += "      " + ((Throwable)i.next()).getMessage() + "\n";
        }
        code += "   *)\n";

        LinkedList recordFields = new LinkedList();
        for(Iterator i = classInfo.methodInfos_.iterator(); i.hasNext(); )
        {
            generateMLTypeOfMethod(recordFields, (MethodInfo)i.next());
        }
        for(Iterator i = classInfo.fieldInfos_.iterator(); i.hasNext(); )
        {
            generateMLTypeOfField(recordFields, (FieldInfo)i.next());
        }
        TreeSet supers = new TreeSet(new ClassComparator());
        collectSuperClasses(supers, classInfo.clazz_);
        code += "  type instance = \n";
        code += "       (\n";
        code += "         {\n";
        for(Iterator i = recordFields.iterator(); i.hasNext();)
        {
            String field = (String)i.next();
            code += "           " + field;
            if(i.hasNext()){code += ",";}
            code += "\n";
        }
        code += "         },\n";
        code += "         {\n";
        for(Iterator i = supers.iterator(); i.hasNext();){
            Class sup = (Class)i.next();
            code += "           " + FQNToFieldLabel(sup.getName()) + " : unit";
            if(i.hasNext()){code += ",";}
            code += "\n";
        }
        code += "         }\n";
        code += "       ) JC.instance\n";

        code += "  local\n";

        // static block (= class initialization)
        code += "    structure static =\n";
        code += "    struct\n";
        code += "      val CLASSNAME = \"" + getFQN(classInfo) + "\"\n";
        code += "      val classRef = ref JV.null\n";
        code += "      fun getClass () = \n";
        code += "          if JV.isNull (!classRef) \n";
        code += "          then raise Fail \"" + structureName + " is not initialized.\" \n";
        code += "          else !classRef\n";
        for(Iterator i = classInfo.constructorInfos_.iterator(); i.hasNext(); )
        {
            ConstructorInfo info = (ConstructorInfo)i.next();
            code += "      val " + info.MLName_ + "_methodID = ref 0\n";
        }
        for(Iterator i = classInfo.methodInfos_.iterator(); i.hasNext(); )
        {
            MethodInfo info = (MethodInfo)i.next();
            code += "      val " + info.MLName_ + "_methodID = ref 0\n";
        }
        for(Iterator i = classInfo.staticMethodInfos_.iterator(); i.hasNext();)
        {
            MethodInfo info = (MethodInfo)i.next();
            code += "      val " + info.MLName_ + "_methodID = ref 0\n";
        }
        for(Iterator i = classInfo.fieldInfos_.iterator(); i.hasNext(); )
        {
            FieldInfo info = (FieldInfo)i.next();
            code += "      val " + info.MLName_ + "_fieldID = ref 0\n";
        }
        for(Iterator i = classInfo.staticFieldInfos_.iterator(); i.hasNext(); )
        {
            FieldInfo info = (FieldInfo)i.next();
            code += "      val " + info.MLName_ + "_fieldID = ref 0\n";
        }

        code += "      val methods = \n";
        for(Iterator i = classInfo.constructorInfos_.iterator(); i.hasNext(); )
        {
            ConstructorInfo info = (ConstructorInfo)i.next();
            code += "          (" + info.MLName_ + "_methodID, \"<init>\", \"" + info.javaSignature_ + "\") :: \n";
        }
        for(Iterator i = classInfo.methodInfos_.iterator(); i.hasNext(); )
        {
            MethodInfo info = (MethodInfo)i.next();
            code += "          (" + info.MLName_ + "_methodID, \"" + info.javaName_ + "\", \"" + info.javaSignature_ + "\") ::\n";
        }
        code += "          []\n";
        code += "      val staticMethods = \n";
        for(Iterator i = classInfo.staticMethodInfos_.iterator(); i.hasNext();)
        {
            MethodInfo info = (MethodInfo)i.next();
            code += "          (" + info.MLName_ + "_methodID, \"" + info.javaName_ + "\", \"" + info.javaSignature_ + "\") ::\n";
        }
        code += "          []\n";
        code += "      val fields = \n";
        for(Iterator i = classInfo.fieldInfos_.iterator(); i.hasNext();)
        {
            FieldInfo info = (FieldInfo)i.next();
            code += "          (" + info.MLName_ + "_fieldID, \"" + info.javaName_ + "\", \"" + info.javaSignature_ + "\") ::\n";
        }
        code += "          []\n";
        code += "      val staticFields = \n";
        for(Iterator i = classInfo.staticFieldInfos_.iterator(); i.hasNext();)
        {
            FieldInfo info = (FieldInfo)i.next();
            code += "          (" + info.MLName_ + "_fieldID, \"" + info.javaName_ + "\", \"" + info.javaSignature_ + "\") ::\n";
        }
        code += "          []\n";
        code += "    end (* static structure *)\n";

        code += "  in\n";

        code += "  fun static () =\n";
        code += "      JC.initClass\n";
        code += "          (\n";
        code += "            static.CLASSNAME,\n";
        code += "            static.classRef,\n";
        code += "            static.methods,\n";
        code += "            static.staticMethods,\n";
        code += "            static.fields,\n";
        code += "            static.staticFields\n";
        code += "          )\n";

        ////////////////////

        for(Iterator i = classInfo.staticMethodInfos_.iterator(); i.hasNext();)
        {
            MethodInfo info = (MethodInfo)i.next();
            code += generateStaticMethod(info);
        }

        for(Iterator i = classInfo.staticFieldInfos_.iterator(); i.hasNext();)
        {
            FieldInfo info = (FieldInfo)i.next();
            code += generateStaticField(info);
        }

        ////////////////////

        code += "  local\n";

        //////////

        for(Iterator i = classInfo.methodInfos_.iterator(); i.hasNext();)
        {
            MethodInfo info = (MethodInfo)i.next();
            code += generateMethod(info);
        }

        //////////

        for(Iterator i = classInfo.fieldInfos_.iterator(); i.hasNext();)
        {
            FieldInfo info = (FieldInfo)i.next();
            code += generateField(info);
        }

        //////////
        
        LinkedList memberNames = new LinkedList();
        for(Iterator i = classInfo.methodInfos_.iterator(); i.hasNext();)
        {
            MethodInfo info = (MethodInfo)i.next();
            memberNames.add(info.MLName_);
        }
        for(Iterator i = classInfo.fieldInfos_.iterator(); i.hasNext();)
        {
            FieldInfo info = (FieldInfo)i.next();
            if(null != info.getterMLName_)
            {memberNames.add(info.getterMLName_);}
            if(null != info.setterMLName_)
            {memberNames.add(info.setterMLName_);}
        }
        code += "  val VTBL =\n";
        code += "      {\n";
        for(Iterator i = memberNames.iterator(); i.hasNext();)
        {
            String name = (String)i.next();
            code += "        " + name + " = " + name;
            if(i.hasNext()){code += ",";}
            code += "\n";
        }
        code += "      }\n";

        //////////
        
        code += "  in\n";

        for(Iterator i = classInfo.constructorInfos_.iterator(); i.hasNext();)
        {
            ConstructorInfo info = (ConstructorInfo)i.next();
            code += generateConstructor(info);
        }

        code += "  fun " + structureName + " object = (JC.cast (static.getClass()) VTBL object) : instance\n";
        code += "  fun isInstance object = JC.isInstance (static.getClass()) object\n";
        code += "  fun class () = static.getClass()\n";
        code += "  end (* end of local *)\n";

        code += "  end (* end of local *)\n";

        code += "end; (* end of structure " + structureName + " *)\n";

        code += "val " + structureName + " = " + structureName + "." + structureName + ";\n";

        return code;
    }

    String generateClasses(Collection classInfos)
        throws NonsupportedTypeException
    {
        String code = "";
        for(Iterator i = classInfos.iterator(); i.hasNext(); )
        {
            code += generateClass((ClassInfo)i.next());
        }
        return code;
    }

    String generatePackage(PackageInfo pck)
        throws NonsupportedTypeException
    {
        String code = "";
        code += "structure " + pck.MLName_ + " =\n";
        code += "struct\n";
        code += generatePackages(pck.packageInfos_.values());
        code += generateClasses(pck.classInfos_.values());
        code += generateStaticFunction(pck.packageInfos_.values(),
                                       pck.classInfos_.values());
        code += "end (* end of " + pck.MLName_ + " *)\n";
        return code;
    }

    String generatePackages(Collection packageInfos)
        throws NonsupportedTypeException
    {
        String code = "";
        for(Iterator i = packageInfos.iterator(); i.hasNext(); )
        {
            PackageInfo child = (PackageInfo)i.next();
            code += generatePackage(child);
        }
        return code;
    }

    String generateStaticFunction(Collection packageInfos,
                                  Collection classInfos)
    {
        String code = "";
        code += "  fun static () = \n";
        code += "      (\n";
        for(Iterator i = classInfos.iterator(); i.hasNext(); )
        {
            code += "        " + ((ClassInfo)i.next()).MLName_ + ".static ();\n";
        }
        for(Iterator i = packageInfos.iterator(); i.hasNext(); )
        {
            code += "        " + ((PackageInfo)i.next()).MLName_ + ".static ();\n";
        }
        code += "        ()\n";
        code += "      )\n";
        return code;
    }

    public String generate(Collection packageInfos,
                           Collection classInfos)
        throws NonsupportedTypeException
    {
        String code = "";
        code += "local\n";
        code += "  structure JV = Java.Value\n";
        code += "  structure JC = Java.ClassHelper\n";
        code += "in\n";
        code += generatePackages(packageInfos);
        code += generateClasses(classInfos);
        code += generateStaticFunction(packageInfos, classInfos);
        code += "end (* end of local *) \n";
        return code;
    }

    public String generate(String namespaceName,
                           Collection packageInfos,
                           Collection classInfos)
        throws NonsupportedTypeException
    {
        String code = "";
        code += "structure " + namespaceName + " =\n";
        code += "struct\n";
        code += generate(packageInfos, classInfos);
        code += "end (* end of " + namespaceName + " *)\n";
        return code;
    }

}
