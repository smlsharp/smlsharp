/**
 * anonymize.cpp
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * for LLVM 5.0.2, 6.0.1, 7.0.1, 8.0.1, 9.0.0, 10.0.0, 11.0.0, 11.1.0, 12.0.0,
 *          13.0.1, 14.0.6, 15.0.7, 16.0.6, 17.0.6, 18.1.8, 19.1.0
 */

#include <llvm/Support/raw_ostream.h>
#include <llvm/Support/SourceMgr.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/IRReader/IRReader.h>
#include <llvm/IR/Instructions.h>
using namespace llvm;

static const char idchars1[] = {
	'a','b','c','d','e','f','g','h','i','j','k','l','m',
	'n','o','p','q','r','s','t','u','v','w','x','y','z',
	'A','B','C','D','E','F','G','H','I','J','K','L','M',
	'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'
};
static const char idchars2[] = {
	'a','b','c','d','e','f','g','h','i','j','k','l','m',
	'n','o','p','q','r','s','t','u','v','w','x','y','z',
	'A','B','C','D','E','F','G','H','I','J','K','L','M',
	'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
	'0','1','2','3','4','5','6','7','8','9'
};

static unsigned int idcount;

static std::string
generate()
{
	std::string s;
	unsigned int c = idcount++;

	for (;;) {
		if (c < sizeof(idchars1)) {
			s.insert(s.begin(), idchars1[c]);
			break;
		} else {
			c -= sizeof(idchars1);
			s.insert(s.begin(), idchars2[c % sizeof(idchars2)]);
			c /= sizeof(idchars2);
		}
	}
	return s;
}

static AttributeList
minimizeAttr(LLVMContext &c, AttributeList s)
{
	AttributeList ret;

#if LLVM_VERSION_MAJOR <= 13
	for (unsigned i = s.index_begin(), e = s.index_end(); i != e; ++i) {
#else
	for (unsigned i : s.indexes()) {
#endif
		for (Attribute a : s.getAttributes(i)) {
			if (a.hasAttribute(Attribute::UWTable)
			    || a.hasAttribute(Attribute::NoUnwind)
			    || a.hasAttribute(Attribute::NoReturn)
			    || a.hasAttribute(Attribute::NoInline)
			    || a.hasAttribute(Attribute::InReg)) {
#if LLVM_VERSION_MAJOR <= 13
				ret = ret.addAttribute(c, i, a);
#else
				ret = ret.addAttributeAtIndex(c, i, a);
#endif
			}
		}
	}
	return ret;
}

static void
setNameIncomingBlocks(const PHINode *p)
{
	for (unsigned i = 0, e = p->getNumIncomingValues(); i < e; ++i) {
		auto *b = p->getIncomingBlock(i);
		if (b->hasNUses(0) && b->getName() == "")
			b->setName(generate());
	}
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

#if LLVM_VERSION_MAJOR <= 16
	for (auto &g : m->getGlobalList()) {
#else
	for (auto &g : m->globals()) {
#endif
		if (g.hasLocalLinkage() && g.hasAtLeastLocalUnnamedAddr())
			g.setName(generate());
	}

	for (auto &f : m->getFunctionList()) {
		f.setAttributes(minimizeAttr(ctxt, f.getAttributes()));
		idcount = 0;
		for (auto &v : f.args())
			v.setName(generate());
		for (auto &b : f) {
			b.setName("");
			if (!b.hasNUses(0))
				b.setName(generate());
			for (auto &i : b) {
				i.setName("");
				if (!i.getType()->isVoidTy())
					i.setName(generate());
				if (PHINode *p = dyn_cast<PHINode>(&i))
					setNameIncomingBlocks(p);
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
