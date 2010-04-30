(**
 * LinkageUnitPickler
 * 
 * @copyright (c) 2006, Tohoku University. 
 * @author Liu Bochao
 * @version $Id: LinkageUnitPickler.sml,v 1.13 2008/03/18 06:20:49 bochao Exp $
 *)
structure LinkageUnitPickler =
struct
      
   structure P = Pickle
   
   val typeSig = 
       P.conv
           ((fn (boundTyConIdSet, env) =>
                {boundTyConIdSet = boundTyConIdSet, env = env}),
            (fn {boundTyConIdSet, env} =>
                (boundTyConIdSet, env)))
           (P.tuple2 (TypesPickler.tyConIdSet, TypesPickler.interfaceEnv))
        
   fun print message = 
       (TextIO.output (TextIO.stdErr, message); TextIO.flushOut TextIO.stdErr)

   val staticEnvSectionName = ".sml#.staticenvs"
   val staticEnvPu = P.tuple4(P.string, typeSig, typeSig, TypesPickler.interfaceEnv)
   fun linkageUnitWriter ({fileName, import, require, export, object} : LinkageUnit.linkageUnit) outputFileName =
       let
           val pickleBuffer = ref NONE
           val pickleChannel =
               ByteArrayChannel.openOut {buffer = pickleBuffer}

           val _ = print "[writing static environments ..."
           val writer =
               {
                putByte = fn byte => #send pickleChannel byte,
                getPos = #getPos pickleChannel,
                seek = #seek pickleChannel
               }

           val _ =  Pickle.pickle staticEnvPu (fileName, import, require, export) (Pickle.makeOutstream writer)
           val _ = print "done]\n"

           val _ = #close pickleChannel ()
           val contextSection =
               {
                sectionName = staticEnvSectionName,
                content = valOf (!pickleBuffer)
               }

           val _ = print "[writing dynamic environments ..."
           val outputFileChannel =
               FileChannel.openOut {fileName = outputFileName}
           val _ = ELFWriterLE.write (#sendArray outputFileChannel, object, [contextSection])
           val _ = #close outputFileChannel ()
           val _ = print "done]\n"
           val _ = print ("["^outputFileName^" is generated]\n")
       in
           ()
       end

   fun getSourceChannel sourceFileName =
       let
           val fileChannel = FileChannel.openIn {fileName = sourceFileName}
           val contents = ChannelUtility.getAll fileChannel
           val _ = #close fileChannel ()
           val sourceChannel =
               ByteVectorChannel.openSliceIn
                   {buffer = contents, start = 0, lenOpt = NONE}
       in
           sourceChannel
       end

   fun linkageUnitReader objectFileName =
       let
           val channel = getSourceChannel objectFileName
           val buf = ChannelUtility.getAll channel
           val buf = Word8Array.tabulate 
                         (
                          Word8Vector.length buf,
                          (fn i => Word8Vector.sub (buf, i))
                         )
           val {objectFile, extraSections} = ELFReader.read buf
           val pickledEnv = 
               case SEnv.find (extraSections, staticEnvSectionName) of
                   SOME x => Word8ArraySlice.vector x
                 | NONE => raise Control.Bug ("no static environments in object file" ^objectFileName)
           val channel = ByteVectorChannel.openIn {buffer = pickledEnv}
           val reader =
               {
                getByte = fn () =>
                             case #receive channel () of
                                 SOME byte => byte
                               | NONE => raise Control.Bug "unexpected EOF of library",
                getPos = NONE,
                seek = NONE
               }
           val _ = print "restoring static environment..."
           val (fileName, import, require, export) =
               Pickle.unpickle staticEnvPu (Pickle.makeInstream reader)
               handle exn => raise Control.Bug ("malformed compiled code:" ^ exnMessage exn)
           val _ = print "done\n"
       in
           {fileName = fileName,
            import = import,
            require = require,
            export = export,
            object = objectFile} : LinkageUnit.linkageUnit
       end
end
           
