/**
 * SMLSharpGC.c
 * @copyright (c) 2013, Tohoku University.
 * @author UENO Katsuhiro
 */

#include <llvm/CodeGen/GCStrategy.h>
#include <llvm/CodeGen/GCMetadataPrinter.h>
#include <llvm/CodeGen/AsmPrinter.h>
#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/IntrinsicInst.h>
#include <llvm/Target/TargetMachine.h>
#include <llvm/Target/TargetLoweringObjectFile.h>
#include <llvm/Target/TargetFrameLowering.h>
#include <llvm/Target/Mangler.h>
#include <llvm/MC/MCStreamer.h>
#include <llvm/MC/MCContext.h>

using namespace llvm;

namespace {

class SMLSharpGC : public GCStrategy {
public:
	SMLSharpGC();
	bool initializeCustomLowering(Module &F);
	bool performCustomLowering(Function &F);
};

static GCRegistry::Add<SMLSharpGC>
X("smlsharp", "smlsharp garbage collector");

class SMLSharpGCPrinter : public GCMetadataPrinter {
	MCSymbol *codeBegin;
public:
	void beginAssembly(AsmPrinter &AP);
	void finishAssembly(AsmPrinter &AP);
};

static GCMetadataPrinterRegistry::Add<SMLSharpGCPrinter>
Y("smlsharp", "smlsharp garbage collector");

} // namespace

SMLSharpGC::SMLSharpGC()
{
	InitRoots = true;
	UsesMetadata = true;
	CustomRoots = true;
	NeededSafePoints = 1 << GC::PostCall;
}

bool
SMLSharpGC::initializeCustomLowering(Module &m)
{
	return false;
}

static unsigned int
countGCRoots(Function &f, unsigned int &headerCount)
{
	unsigned int rootCount = 0;
	headerCount = 0;
	for (Function::iterator bi = f.begin(), be = f.end(); bi != be; ++bi) {
		for (BasicBlock::iterator ii = bi->begin(), ie = bi->end();
		     ii != ie; ++ii) {
			IntrinsicInst *ci = dyn_cast<IntrinsicInst>(ii);
			if (!ci)
				continue;
			Function *g = ci->getCalledFunction();
			if (!g || g->getIntrinsicID() != Intrinsic::gcroot)
				continue;
			Constant *c = dyn_cast<Constant>(ci->getArgOperand(1));
			if (c->isNullValue())
				rootCount++;
			else
				headerCount++;
		}
	}
	return rootCount;
}

bool
SMLSharpGC::performCustomLowering(Function &f)
{
	unsigned int rootCount, headerCount;
	rootCount = countGCRoots(f, headerCount);

	// If there is some gcroots, allocate a header slot.
	if (rootCount == 0 || headerCount > 0)
		return false;

	Type *voidPtrTy = Type::getInt8PtrTy(f.getContext());
	Type *i8Ty = Type::getInt8Ty(f.getContext());
	Constant *int1 = Constant::getIntegerValue(i8Ty, APInt(8, 1));
	Constant *nonNullMeta = ConstantExpr::getIntToPtr(int1, voidPtrTy);

	// Allocate a header slot for each function at the beginning of
	// the function and initialize it by null.
	// Specifying non-null metadata to @llvm.gcroot indicates the header.
	BasicBlock::iterator i = f.getEntryBlock().begin();
	IRBuilder<> builder(i->getParent(), i);
	Instruction *p = builder.CreateAlloca(voidPtrTy, 0, "header");
	Value *gcroot = Intrinsic::getDeclaration(f.getParent(),
						  Intrinsic::gcroot);
	builder.CreateCall2(gcroot, p, nonNullMeta);
	builder.CreateStore(Constant::getNullValue(voidPtrTy), p);

	return true;
}

static MCSymbol *
emitGlobalLabel(AsmPrinter &ap, const Module &m, const Twine &prefix)
{
	const std::string &moduleId = m.getModuleIdentifier();
	SmallString<128> name;
	ap.Mang->getNameWithPrefix(name, prefix + moduleId);
	MCSymbol *sym = ap.OutContext.GetOrCreateSymbol(name);
	ap.OutStreamer.EmitSymbolAttribute(sym, MCSA_Global);
	ap.OutStreamer.EmitLabel(sym);
	return sym;
}

void
SMLSharpGCPrinter::beginAssembly(AsmPrinter &ap)
{
	ap.OutStreamer.SwitchSection(ap.getObjFileLowering().getTextSection());
	codeBegin = emitGlobalLabel(ap, getModule(), "_SML_b");
}

static int
searchHeaderOffset(GCFunctionInfo &md)
{
	for (GCFunctionInfo::roots_iterator
		     ri = md.roots_begin(), re = md.roots_end();
	     ri != re; ++ri) {
		if (!ri->Metadata->isNullValue())
			return ri->StackOffset;
	}
	report_fatal_error("header not found");
}

static void
emitUInt16(AsmPrinter &ap, unsigned int n)
{
	if (n > 65535)
		report_fatal_error("emitUInt16: out of range");
	ap.EmitInt16(n);
}

static void
emitInt16(AsmPrinter &ap, int n)
{
	if (n > 32767 || n < -32768)
		report_fatal_error("emitInt16: out of range");
	ap.EmitInt16(n);
}

static void
emitEntry(AsmPrinter &ap, GCFunctionInfo &md)
{
	// skip if no safe point
	if (md.size() == 0)
		return;

	bool stackGrowsDown =
		ap.TM.getFrameLowering()->getStackGrowthDirection()
		== TargetFrameLowering::StackGrowsDown;
	unsigned int ptrSize = ap.TM.getDataLayout()->getPointerSize();

	ap.OutStreamer.AddComment(md.getFunction().getName());

	ap.OutStreamer.AddComment("number of safe points");
	emitUInt16(ap, md.size());

	if (md.getFrameSize() % ptrSize != 0)
		report_fatal_error("unexpected frame size");

	int64_t frameBeginOffset = md.getFrameSize() / ptrSize;
	if (!stackGrowsDown)
		frameBeginOffset = -frameBeginOffset;

	ap.OutStreamer.AddComment("frame begin offset");
	emitInt16(ap, frameBeginOffset);

	if (md.roots_size() == 0) {
		// we are interested only in stack size if there is no gcroot
		ap.OutStreamer.AddComment("root size");
		emitUInt16(ap, 0);
		return;
	}

	int headerOffset = searchHeaderOffset(md);

	// stack information in each safe point is identical.
	// only print first one.
	GCFunctionInfo::iterator si = md.begin();

	unsigned int rootCount = 0;
	for (GCFunctionInfo::live_iterator
		     li = md.live_begin(si), le = md.live_end(si);
	     li != le; ++li) {
		if (li->Metadata->isNullValue())
			rootCount++;
	}

	if (headerOffset % ptrSize != 0)
		report_fatal_error("unexpected header offset");

	ap.OutStreamer.AddComment("root size");
	emitUInt16(ap, rootCount + 1);
	ap.OutStreamer.AddComment("header offset");
	emitInt16(ap, headerOffset / ptrSize);

	ap.OutStreamer.AddComment("root offsets");
	for (GCFunctionInfo::live_iterator
		     li = md.live_begin(si), le = md.live_end(si);
	     li != le; ++li) {
		if (!li->Metadata->isNullValue()) {
			if (li->StackOffset != headerOffset)
				report_fatal_error("unexpected header slot");
			continue;
		}
		if (li->StackOffset % ptrSize != 0)
			report_fatal_error("unexpected stack offset");
		int offset = li->StackOffset / ptrSize;

		// offset must be an offset from the end of frame.
		if (stackGrowsDown == (offset < 0))
			offset = frameBeginOffset + offset;

		emitInt16(ap, offset);
	}
}

static void
emitAddrList(AsmPrinter &ap, MCSymbol *base, GCFunctionInfo &md)
{
	// skip if no safe point
	if (md.size() == 0)
		return;

	unsigned int ptrSize = ap.TM.getDataLayout()->getPointerSize();

	ap.OutStreamer.AddComment(md.getFunction().getName());

	for (GCFunctionInfo::iterator pi = md.begin(), pe = md.end();
	     pi != pe; ++pi) {
		ap.EmitLabelDifference(pi->Label, base, ptrSize);
	}
}

void
SMLSharpGCPrinter::finishAssembly(AsmPrinter &ap)
{
	unsigned int ptrSize = ap.TM.getDataLayout()->getPointerSize();
	unsigned int ptrSizeNumBits = ptrSize == 8 ? 3 : 2;

	ap.OutStreamer.SwitchSection
		(ap.getObjFileLowering().getSectionForConstant
		 (SectionKind::getReadOnly()));
	ap.EmitAlignment(ptrSizeNumBits);

	MCSymbol *mapBegin = emitGlobalLabel(ap, getModule(), "_SML_r");

	MCSymbol *addrsBegin = ap.OutContext.CreateTempSymbol();
	ap.OutStreamer.AddComment("addr list offset");
	ap.EmitLabelDifference(addrsBegin, mapBegin, ptrSize);

	for (iterator fi = begin(), fe = end(); fi != fe; ++fi)
		emitEntry(ap, **fi);

	ap.EmitAlignment(ptrSizeNumBits);
	ap.OutStreamer.EmitLabel(addrsBegin);

	for (iterator fi = begin(), fe = end(); fi != fe; ++fi)
		emitAddrList(ap, codeBegin, **fi);
}
