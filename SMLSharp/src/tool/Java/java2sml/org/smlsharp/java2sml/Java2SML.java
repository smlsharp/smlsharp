package org.smlsharp.java2sml;

import java.io.FileWriter;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.TreeMap;

/*
 * $ java Java2SML.jar foo.bar.Boo foo.hoge.Fuga
 * Java2SML generates following SML code to a file 'foo.sml'.
 *
 * structure foo =
 * struct
 *   structure bar =
 *   struct
 *     structure Boo =
 *     struct
 *       :
 *     end
 *   end
 *   structure hoge =
 *   struct
 *     structure Fuga =
 *     struct
 *       :
 *     end
 *   end
 * end
 *
 * <hr>
 * options.
 *
 * <dl>
 * <dt>--no-package</dt>
 * <dd>Do not generate structures mapped to packages. For example,
 * <pre>
 *   $ java Java2SML.jar --no-package foo.bar.Boo
 * </pre>
 * generates following code.
 * <pre>
 * structure Boo =
 * struct
 *   :
 * end
 * </pre>
 * </dd>
 * <dt>--namespace NAME</dt>
 * <dd>Generate code in a structure NAME. For example,
 * <pre>
 *   $ java Java2SML.jar --namespace X foo.bar.Boo
 * </pre>
 * generates following code.
 * <pre>
 * structure X =
 * struct
 *   structure foo =
 *   struct
 *     structure bar =
 *     struct
 *       structure Boo =
 *       struct
 *         :
 *       end
 *     end
 *   end
 * end
 * </pre>
 * </dd>
 *
 * <dt>-o FILE</dt>
 * <dd>
 *   Place the output into FILE.
 * </dd>
 *
 * </dl>
 *
 * <hr>
 * overload.
 * <p>
 *  To give unique name, dummy characters are appended to names of overloaded
 * methods, except for the method which takes the least number of arguments
 * among them.
 * </p>
 * <p>
 * For example, if a java class has three overloaded methods,
 * <pre>
 *  String foo();
 *  String foo(int x);
 *  String foo(String x);
 * </pre>
 * three functions are generated in SML code as follows.
 * <pre>
 *  foo : unit -> string
 *  foo'1 : int -> string
 *  foo'2 : string -> string
 * </pre>
 * </p>
 *
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Java2SML.java,v 1.7 2007/11/23 07:57:12 kiyoshiy Exp $
 */
public class Java2SML
{

    //////////////////////////////////////////////////////////////////////

    static PackageInfo packageOfClass(PackageInfo root, Class clazz)
    {
        String[] FQN = clazz.getName().split("\\.");
        PackageInfo current = root;
        // FQN[FQN.length - 1] is class name.
        for(int index = 0; index < FQN.length - 1; index += 1)
        {
            String name = FQN[index];
            PackageInfo child =
            (PackageInfo)current.packageInfos_.get(name);
            if(null == child){
                child = new PackageInfo(name, new TreeMap(), new TreeMap());
                current.packageInfos_.put(name, child);
            }
            current = child;
        }
        return current;
    }

    static final String usage =
    "java2sml OPTIONS\n" +
    "    -o <file>           Place the output to <file>.\n" +
    "    --namespace <name>  Enclose generated code in a <name> structure.\n" +
    "    --help              Display this information\n";

    static String makeHeader(String[] args)
    {
        String header = "";
        header += "(*\n";
        header += " * generated from:\n";
        header += " *   java2sml.sh";
        for(int index = 0; index < args.length; index += 1)
        {
            header += " " + args[index];
        }
        header += "\n";
        header += " *)\n";

        return header;
    }

    public static void main(String[] args)
        throws Exception
    {
        String outputFileName = null; // 'null' indicates STDOUT
        String namespaceName = null;
        int argIndex = 0;
        for(; argIndex < args.length; argIndex += 1)
        {
            if("-o".equals(args[argIndex])){
                argIndex += 1;
                if(args.length <= argIndex){
                    throw
                    new IllegalArgumentException("-o requires FILE name.");
                }
                outputFileName = args[argIndex];
            }
            else if("--namespace".equals(args[argIndex])){
                argIndex += 1;
                if(args.length <= argIndex){
                    throw
                    new IllegalArgumentException
                          ("--namespace requires namespace.");
                }
                namespaceName = args[argIndex];
            }
            else if("--help".equals(args[argIndex])){
                System.err.println(usage);
                return;
            }
            else{
                break;
            }
        }

        if(args.length <= argIndex){
            return;
        }

        ClassTranslator translator = new ClassTranslator();

        PackageInfo root = new PackageInfo("$", new TreeMap(), new TreeMap());
        LinkedList classInfos = new LinkedList();
        for(; argIndex < args.length; argIndex += 1)
        {
            Class clazz = Class.forName(args[argIndex]);
            PackageInfo pck = packageOfClass(root, clazz);
            pck.classInfos_.put(clazz.getName(),
                                translator.translateClass(clazz));
        }

        SMLCodeGenerator generator = new SMLCodeGenerator();
        String code =
          (namespaceName == null)
          ? generator.generate(root.packageInfos_.values(),
                               root.classInfos_.values())
          : generator.generate(namespaceName,
                               root.packageInfos_.values(),
                               root.classInfos_.values());
        
        Writer output;
        if(null == outputFileName){
            output = new OutputStreamWriter(System.out);
        }
        else{
            output = new FileWriter(outputFileName);
        }
        output.write(makeHeader(args));
        output.write(code);
        output.close();

        return;
    }
}
