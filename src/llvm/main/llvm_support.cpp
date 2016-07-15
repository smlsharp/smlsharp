/**
 * llvm_support.c
 * @copyright (c) 2013, Tohoku University.
 * @author UENO Katsuhiro
 */

#include <llvm/ADT/Triple.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/Instructions.h>
#include <llvm/Support/TargetSelect.h>
#include <llvm/Target/TargetMachine.h>
#include <llvm/Support/TargetRegistry.h>

using namespace llvm;

namespace sml {

extern "C"
void
sml_llvm_initialize()
{
	InitializeAllTargetInfos();
	InitializeAllTargets();
	InitializeAllTargetMCs();
	InitializeAllAsmPrinters();
	InitializeAllAsmParsers();
}

extern "C"
const char *
sml_llvm_version()
{
	static const char version[] = LLVM_VERSION_STRING;
	return (const char *)&version;
}

extern "C"
void
sml_LLVMAddFunctionReturnAttr(LLVMValueRef fn, LLVMAttribute attr)
{
	Function *func = unwrap<Function>(fn);
	LLVMContext &context = func->getContext();
	AttrBuilder b(attr);
	func->setAttributes
		(func->getAttributes().addAttributes
		 (context,
		  AttributeSet::ReturnIndex,
		  AttributeSet::get(context, AttributeSet::ReturnIndex, b)));
}

extern "C"
LLVMBool
sml_LLVMGetTargetFromArchAndTriple(const char *arch, const char *triple,
				   LLVMTargetRef *ret, char **err)
{
	std::string error;
	Triple tri(triple);
	const Target *t = TargetRegistry::lookupTarget(arch, tri, error);
	if (!t) {
		*err = strdup(error.c_str());
		return 1;
	}
	*ret = reinterpret_cast<LLVMTargetRef>(const_cast<Target*>(t));
	return 0;
}
#include <stdio.h>

extern "C"
void
sml_SetAtomic(LLVMValueRef v, AtomicOrdering ordering,
	      SynchronizationScope scope)
{
	Value *p = unwrap<Value>(v);
	if (LoadInst *li = dyn_cast<LoadInst>(p))
		li->setAtomic(ordering, scope);
	else if (StoreInst *si = dyn_cast<StoreInst>(p))
		si->setAtomic(ordering, scope);
	else
		llvm_unreachable("sml_LLVMSetAtomic");
}

extern "C"
void
sml_SetMustTailCall(LLVMValueRef v)
{
	unwrap<CallInst>(v)->setTailCallKind(CallInst::TCK_MustTail);
}

} // namespace
