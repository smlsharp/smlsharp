/**
 * anonymize.cpp
 * @copyright (c) 2019, Tohoku University.
 * @author UENO Katsuhiro
 * for LLVM 5.0.2, 6.0.1, 7.0.1, 8.0.1, 9.0.0, 10.0.0, 11.0.0
 */

#include <llvm/Support/raw_ostream.h>
#include <llvm/Support/SourceMgr.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/IRReader/IRReader.h>
#include <llvm/IR/Instructions.h>
using namespace llvm;

static AttributeList
minimizeAttr(LLVMContext &c, AttributeList s)
{
	AttributeList ret;
	for (unsigned i = s.index_begin(), e = s.index_end(); i != e; ++i) {
		for (Attribute a : s.getAttributes(i)) {
			if (a.hasAttribute(Attribute::UWTable)
			    || a.hasAttribute(Attribute::NoUnwind)
			    || a.hasAttribute(Attribute::NoReturn)
			    || a.hasAttribute(Attribute::NoInline)
			    || a.hasAttribute(Attribute::InReg)) {
				ret = ret.addAttribute(c, i, a);
			}
		}
	}
	return ret;
}

int
main(int argc, char **argv)
{
	LLVMContext ctxt;
	SMDiagnostic err;
	auto m = parseIRFile("-", err, ctxt);
	if (!m) {
		err.print(argv[0], errs());
		return 1;
	}

	for (auto &v : m->getGlobalList()) {
		if (v.hasLocalLinkage() && v.hasAtLeastLocalUnnamedAddr())
			v.setName("");
	}
	for (auto &f : m->getFunctionList()) {
		f.setAttributes(minimizeAttr(ctxt, f.getAttributes()));
		for (auto &v : f.args())
			v.setName("");
		for (auto &b : f) {
			b.setName("");
			for (auto &i : b) {
				i.setName("");
				if (CallInst *c = dyn_cast<CallInst>(&i)) {
					auto s = c->getAttributes();
					c->setAttributes(minimizeAttr(ctxt, s));
				}
			}
		}
	}

	outs() << *m;
	return 0;
}
