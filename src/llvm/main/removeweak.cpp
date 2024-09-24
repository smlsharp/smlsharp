/**
 * removeweak.cpp
 * @copyright (C) 2024 SML# Development Team.
 * @author UENO Katsuhiro
 * for LLVM 3.9.1, 4.0.1, 5.0.2, 6.0.1, 7.0.1, 11.1.0, 12.0.0, 13.0.1,
 *          14.0.6, 15.0.7, 16.0.6, 17.0.6, 18.1.8, 19.1.0
 */

#include <cstring>
#include <llvm/Support/raw_ostream.h>
#include <llvm/Support/SourceMgr.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/IRReader/IRReader.h>
using namespace llvm;

int
main(int argc, char **argv)
{
	bool define = (argc > 1 && std::strcmp(argv[1], "-D") == 0);

	LLVMContext ctxt;
	SMDiagnostic err;

	auto m = parseIRFile("-", err, ctxt);
	if (!m) {
		err.print(argv[0], errs());
		return 1;
	}

#if LLVM_VERSION_MAJOR <= 16
	for (auto &g : m->getGlobalList()) {
#else
	for (auto &g : m->globals()) {
#endif
		if (g.hasWeakLinkage()) {
			g.setLinkage(GlobalValue::ExternalLinkage);
			if (!define)
				g.setInitializer(NULL);
		}
	}

	for (auto &f : m->getFunctionList()) {
		if (f.hasWeakLinkage()) {
			if (define)
				f.setLinkage(GlobalValue::ExternalLinkage);
			else
				f.deleteBody();
		}
	}

	outs() << *m;
	return 0;
}
