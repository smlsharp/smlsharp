#include <llvm/Support/raw_ostream.h>
#include <llvm/Support/SourceMgr.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/IRReader/IRReader.h>

using namespace llvm;

int
main(int argc, char **argv)
{
	LLVMContext &context = getGlobalContext();
	SMDiagnostic err;
	std::unique_ptr<Module> m = parseIRFile("-", err, context);
	if (!m) {
		err.print(argv[0], errs());
		return 1;
	}

	for (auto &v : m->getGlobalList()) {
		if (v.hasLocalLinkage() && v.hasUnnamedAddr())
			v.setName("");
	}
	for (auto &f : m->getFunctionList()) {
		for (auto &a : f.getArgumentList())
			a.setName("");
		for (auto &b : f.getBasicBlockList()) {
			b.setName("");
			for (auto &i : b.getInstList())
				i.setName("");
		}
	}

	outs() << *m;
	return 0;
}
