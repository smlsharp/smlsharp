/**
 * llvm_support.c
 * @copyright (c) 2013, Tohoku University.
 * @author UENO Katsuhiro
 */

#include <llvm/Config/llvm-config.h>
#include <llvm/CodeGen/LinkAllCodegenComponents.h>
#include <llvm/Support/raw_ostream.h>
#include <llvm/Support/FormattedStream.h>
#include <llvm/Support/TargetSelect.h>
#include <llvm/Support/TargetRegistry.h>
#include <llvm/Target/TargetLibraryInfo.h>
#include <llvm/Target/TargetMachine.h>
#include <llvm/MC/SubtargetFeature.h>
#include <llvm/PassManager.h>
#include <llvm/IR/Value.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/DataLayout.h>
#include <llvm/IR/Module.h>
#include <llvm/Transforms/IPO/PassManagerBuilder.h>
#include <llvm/Transforms/IPO.h>
#include <llvm/Analysis/Verifier.h>
#include <llvm/Assembly/PrintModulePass.h>
#include <llvm/Bitcode/ReaderWriter.h>

using namespace llvm;

namespace sml {

extern "C"
void
sml_llvm_initialize()
{
#if 1
	InitializeAllTargetInfos();
	InitializeAllTargets();
	InitializeAllTargetMCs();
	InitializeAllAsmPrinters();
	InitializeAllAsmParsers();
#else
	LLVM_NATIVE_TARGETINFO();
	LLVM_NATIVE_TARGET();
	LLVM_NATIVE_TARGETMC();
	LLVM_NATIVE_ASMPARSER();
	LLVM_NATIVE_ASMPRINTER();
#endif
}

#define VERSION_STRING_(major, minor) #major "." #minor
#define VERSION_STRING(major, minor) VERSION_STRING_(major, minor)

extern "C"
const char *
sml_llvm_version()
{
	static const char version[] =
		VERSION_STRING(LLVM_VERSION_MAJOR, LLVM_VERSION_MINOR);
	return (const char *)&version;
}

extern "C"
void
sml_llvm_add_func_attr(LLVMValueRef fn, unsigned int index, LLVMAttribute attr)
{
	Function *func = unwrap<Function>(fn);
	const AttributeSet pal = func->getAttributes();
	LLVMContext &context = func->getContext();
	AttrBuilder b(attr);
	const AttributeSet attrs = AttributeSet::get(context, index, b);
	func->setAttributes(pal.addAttributes(context, index, attrs));
}

static void
optimize_module(DataLayout *dataLayout, PassManagerBase &mpm, Module *module,
		unsigned int optLevel, unsigned int sizeLevel)
{
	OwningPtr<FunctionPassManager> fpm(new FunctionPassManager(module));

	if (dataLayout)
		fpm.get()->add(new DataLayout(*dataLayout));

	PassManagerBuilder builder;
	builder.OptLevel = optLevel;
	builder.SizeLevel = sizeLevel;

	if (optLevel == 1) {
		builder.Inliner = createAlwaysInlinerPass();
	} else {
		unsigned int threshold;
		if (optLevel >= 3)
			threshold = 275;
		else if (sizeLevel >= 2)
			threshold = 25;
		else if (sizeLevel >= 1)
			threshold = 75;
		else
			threshold = 255;
		builder.Inliner = createFunctionInliningPass(threshold);
	}
	builder.DisableUnitAtATime = false; // -funit-at-a-time
	builder.DisableUnrollLoops = false;
	//3.4 builder.DisableSimplifyLibCalls = true; // -disable-simplify-libcalls
	builder.populateFunctionPassManager(*fpm);
	builder.populateModulePassManager(mpm);

	fpm->doInitialization();
	for (Module::iterator i = module->begin(), e = module->end();
	     i != e; ++i)
		fpm->run(*i);
	fpm->doFinalization();
}

enum OutputFileType {
	NullFile,
	AssemblyFile,
	ObjectFile,
	IRFile,
	BitcodeFile
};

static CodeGenOpt::Level optLevelMap[] =
	{CodeGenOpt::None,
	 CodeGenOpt::Less,
	 CodeGenOpt::Default,
	 CodeGenOpt::Aggressive};

static TargetMachine::CodeGenFileType fileTypeMap[] =
	{TargetMachine::CGFT_Null,
	 TargetMachine::CGFT_AssemblyFile,
	 TargetMachine::CGFT_ObjectFile};

#define LOOKUP(map, key) \
	((key) < sizeof(map) / sizeof(*map) ? map[key] : map[0])

bool
sml_llvm_compile(Module *module,
		 const std::string &arch,
		 StringRef cpu,
		 StringRef features,
		 unsigned int optLevel,
		 unsigned int sizeLevel,
		 Reloc::Model relocModel,
		 CodeModel::Model codeModel,
		 OutputFileType fileType,
		 const char *outputFilename,
		 std::string &error)
{
	error = "";
	Triple triple(module->getTargetTriple());
	const Target *target;

	target = TargetRegistry::lookupTarget(arch, triple, error);
	if (!target)
		return true;

	TargetOptions options;
	options.GuaranteedTailCallOpt = true; // tailcallopt
	options.DisableTailCalls = false; // disable-tail-calls
	// use default settings for any other options.

	CodeGenOpt::Level opt = LOOKUP(optLevelMap, optLevel);

	OwningPtr<TargetMachine>
		tm(target->createTargetMachine(triple.getTriple(),
					       cpu,
					       features,
					       options,
					       relocModel,
					       codeModel,
					       opt));
	if (!tm.get()) {
		error = "failed to allocate target machine";
		return true;
	}

	//tm.get()->setMCUseLoc(false); // disable-dot-loc
	//tm.get()->setMCUseCFI(false); // disable-cfi
	//tm.get()->setMCUseDwarfDirectory(true);  // enable-dwarf-directory

	raw_fd_ostream os(outputFilename, error, sys::fs::F_Binary);
	if (!error.empty())
		return true;

	PassManager pm;

	TargetLibraryInfo *tli = new TargetLibraryInfo(triple);
	//tli->disableAllFunctions(); // disable-simplify-libcalls
	pm.add(tli);
	tm.get()->addAnalysisPasses(pm);

	DataLayout *dataLayout;
	if (!module->getDataLayout().empty())
		dataLayout = new DataLayout(module);
	else if (tm.get()->getDataLayout())
		dataLayout = new DataLayout(*tm.get()->getDataLayout());
	else
		dataLayout = 0;

	if (dataLayout)
		pm.add(dataLayout);

	//pm.add(createVerifierPass());

	if (optLevel > 0) {
		optimize_module(dataLayout, pm, module, optLevel, sizeLevel);
		pm.add(createVerifierPass());
	}

	//tm.get()->setAsmVerbosityDefault(true);
	//if (fileType == TargetMachine::CGFT_ObjectFile) tm.get()->setMCRelaxAll(true);  // -mc-relax-all

	formatted_raw_ostream fos;

	if (fileType == IRFile) {
		pm.add(createPrintModulePass(&os));
	} else if (fileType == BitcodeFile) {
		pm.add(createBitcodeWriterPass(os));
	} else {
		fos.setStream(os);
		TargetMachine::CodeGenFileType type =
			LOOKUP(fileTypeMap, fileType);

		if (tm.get()->addPassesToEmitFile(pm, fos, type, false)) {
			error = "failed to generate this file type";
			return true;
		}
	}

	pm.run(*module);

	os.flush();

	return false;
}

static Reloc::Model relocModelMap[] =
	{Reloc::Default,
	 Reloc::Static,
	 Reloc::PIC_,
	 Reloc::DynamicNoPIC};

static CodeModel::Model codeModelMap[] =
	{CodeModel::Default,
	 CodeModel::JITDefault,
	 CodeModel::Small,
	 CodeModel::Kernel,
	 CodeModel::Medium,
	 CodeModel::Large};

extern "C"
LLVMBool
sml_llvm_compile_c(LLVMModuleRef module,
		   const char *arch,
		   const char *cpu,
		   const char * const *attrs,
		   unsigned int numAttrs,
		   unsigned int optLevel,
		   unsigned int sizeLevel,
		   unsigned int relocModel,
		   unsigned int codeModel,
		   enum OutputFileType fileType,
		   const char *outputFilename,
		   char **ret_error)
{
	std::string error;

	SubtargetFeatures features;
	for (unsigned int i = 0; i < numAttrs; i++)
		features.AddFeature(attrs[i]);
	std::string featuresStr = features.getString();

	if (sml_llvm_compile(unwrap(module),
			     arch,
			     cpu,
			     featuresStr,
			     optLevel,
			     sizeLevel,
			     LOOKUP(relocModelMap, relocModel),
			     LOOKUP(codeModelMap, codeModel),
			     fileType,
			     outputFilename,
			     error)) {
		*ret_error = strdup(error.c_str());
		return 1;
	}

	return 0;
}

} // namespace
