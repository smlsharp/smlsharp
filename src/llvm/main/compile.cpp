/**
 * compile.c
 * @copyright (c) 2013, Tohoku University.
 * @author UENO Katsuhiro
 */

#include <string.h>
#include <llvm/Support/TargetSelect.h>
#include <llvm/Support/SourceMgr.h>
#include <llvm/Support/raw_ostream.h>
#include <llvm/Support/MemoryBuffer.h>
#include <llvm/CodeGen/LinkAllCodegenComponents.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/IRReader/IRReader.h>

using namespace llvm;

namespace sml {

enum OutputFileType {
	NullFile,
	AssemblyFile,
	ObjectFile,
	IRFile,
	BitcodeFile
};

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
		 std::string &error);

} // namespace

static std::string *
get_module_id(const MemoryBuffer *buf)
{
	static const std::string prefix = "; ModuleID = '";
	const char *begin = buf->getBufferStart();
	const char *end = buf->getBufferEnd();
	const char *p;
	size_t len;

	if (strncmp(begin, prefix.c_str(), prefix.size()) != 0)
		return NULL;
	begin += prefix.size();

	for (p = begin; p < end; p++) {
		if (*p == '\n' || *p == '\r')
			return NULL;
		if (*p == '\'')
			break;
	}

	return new std::string(begin, p - begin);
}

int
main(int argc, char **argv)
{
	if (argc != 4) {
		errs() << "usage: " << argv[0]
		       << " <triple> <input> <output>\n";
		return 1;
	}

	const char *triple = argv[1];
	const char *inputFilename = argv[2];
	const char *outputFilename = argv[3];

	InitializeAllTargetInfos();
	InitializeAllTargets();
	InitializeAllTargetMCs();
	InitializeAllAsmPrinters();

	LLVMContext &context = getGlobalContext();

	SMDiagnostic err;
	OwningPtr<MemoryBuffer> buf;
	error_code e = MemoryBuffer::getFileOrSTDIN(inputFilename, buf);
	if (e) {
		err = SMDiagnostic(inputFilename, SourceMgr::DK_Error,
				   "failed to open file: " + e.message());
		err.print(argv[0], errs());
		return 1;
	}

	OwningPtr<std::string> module_id(get_module_id(buf.get()));

	OwningPtr<Module> module(ParseIR(buf.take(), err, context));
	if (!module.get()) {
		err.print(argv[0], errs());
		return 1;
	}

	if (module_id.get() != NULL)
		module.get()->setModuleIdentifier(*module_id.get());

	module.get()->setTargetTriple(triple);

	std::string error;
	if (sml::sml_llvm_compile(module.get(),
				  "",        // arch
				  "generic", // use generic cpu for portability
				  "",        // features
				  2,         // optLevel
				  0,         // sizeLevel
				  Reloc::Default,
				  CodeModel::Default,
				  sml::ObjectFile,
				  outputFilename,
				  error)) {
		errs() << argv[0] << ": " << error << '\n';
		return 1;
	}

	return 0;
}
