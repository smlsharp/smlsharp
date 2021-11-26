/**
 * smlsharp_gc.cpp
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * for LLVM 3.9.1, 4.0.1, 5.0.2, 6.0.1, 7.0.1, 8.0.1, 9.0.1, 10.0.0, 11.0.0,
 *          11.1.0, 12.0.0, 13.0.0
 */

#include <llvm/Config/llvm-config.h>
#include <llvm/CodeGen/AsmPrinter.h>
#if LLVM_VERSION_MAJOR >= 13
#include <llvm/IR/GCStrategy.h>
#else
#include <llvm/CodeGen/GCStrategy.h>
#endif
#include <llvm/CodeGen/GCMetadata.h>
#include <llvm/CodeGen/GCMetadataPrinter.h>
#include <llvm/MC/MCStreamer.h>
#include <llvm/MC/MCSymbol.h>
#if LLVM_VERSION_MAJOR == 6
#include <llvm/CodeGen/TargetLoweringObjectFile.h>
#else
#include <llvm/Target/TargetLoweringObjectFile.h>
#endif
#if LLVM_VERSION_MAJOR >= 11
#include <llvm/IR/Module.h>
#include <llvm/MC/SectionKind.h>
#include <llvm/Support/Alignment.h>
#endif
using namespace llvm;

namespace {
class SMLSharpGC : public GCStrategy {
public:
	SMLSharpGC() {
#if LLVM_VERSION_MAJOR <= 7
		NeededSafePoints = 1 << GC::PostCall;
#else
		NeededSafePoints = true;
#endif
		UsesMetadata = 1;
	}
};
class SMLSharpGCPrinter : public GCMetadataPrinter {
public:
	void finishAssembly(Module &, GCModuleInfo &, AsmPrinter &) override;
};
}

static GCRegistry::Add<SMLSharpGC> X("smlsharp", "SML#");
static GCMetadataPrinterRegistry::Add<SMLSharpGCPrinter> Y("smlsharp", "SML#");

static void
EmitUInt16(AsmPrinter &ap, uint64_t value, uint64_t unit = 1)
{
	if (value % unit != 0 || value / unit >= 65536)
		report_fatal_error("EmitUInt16: out of range");
#if LLVM_VERSION_MAJOR <= 10
	ap.OutStreamer->EmitIntValue(value / unit, 2);
#else
	ap.OutStreamer->emitIntValue(value / unit, 2);
#endif
}

static const Function *
FindFunction(const Module &m, StringRef prefix)
{
	for (auto &f : m.getFunctionList()) {
		if (!f.hasExternalLinkage() && f.getName().startswith(prefix))
			return &f;
	}
	return nullptr;
}

/*
 * frame table format:
 *   struct align(uintptr_t) {
 *     uint16_t   NumSafePoints;
 *     uint16_t   FrameSize;                        // in words
 *     uint16_t   NumRoots;
 *     uint16_t   RootOffsets[NumRoots];            // in words
 *     uintptr_t  SafePointOffsets[NumSafePoints];  // in bytes
 *   } Descriptors[]; // terminated with NumSafePoints == 0
 */
static void
EmitFunctionInfo(AsmPrinter &ap, GCFunctionInfo &fi, MCSymbol *base)
{
	// skip functions that have no safe point.
	if (fi.size() == 0) return;

	unsigned ptrsize = ap.getPointerSize();
	ap.OutStreamer->AddComment(fi.getFunction().getName());
	EmitUInt16(ap, fi.size());
	EmitUInt16(ap, fi.getFrameSize(), ptrsize);
	EmitUInt16(ap, fi.roots_size());

	// LLVM does not compute the live set of each safe point
	// (live_begin is an alias of roots_begin).
	// all safe points in a function have the same set of gc roots.
	for (auto i = fi.roots_begin(), ie = fi.roots_end(); i != ie; ++i)
		EmitUInt16(ap, i->StackOffset, ptrsize);

#if LLVM_VERSION_MAJOR <= 10
	ap.OutStreamer->EmitValueToAlignment(ptrsize);
#else
	ap.OutStreamer->emitValueToAlignment(ptrsize);
#endif
	for (auto &p : fi)
		ap.OutStreamer->emitAbsoluteSymbolDiff(p.Label, base, ptrsize);
}

void
SMLSharpGCPrinter::finishAssembly(Module &m, GCModuleInfo &info, AsmPrinter &ap)
{
	const auto *tabb = FindFunction(m, "_SML_tabb");
#if LLVM_VERSION_MAJOR <= 10
	std::string id = tabb ? tabb->getName().substr(9) : "";
#else
	std::string id = tabb ? tabb->getName().substr(9).str() : "";
#endif
	auto *sml_tabb = tabb ? ap.getSymbol(tabb)
		: ap.GetExternalSymbolSymbol("_SML_tabb" + id);
	auto *sml_ftab = ap.GetExternalSymbolSymbol("_SML_ftab" + id);

#if LLVM_VERSION_MAJOR <= 10
	unsigned align = ap.getPointerSize();
#else
	Align align(ap.getPointerSize());
#endif
	ap.OutStreamer->SwitchSection
		(ap.getObjFileLowering().getSectionForConstant
		 (ap.getDataLayout(), SectionKind::getReadOnly(),
		  nullptr, align));
#if LLVM_VERSION_MAJOR <= 10
	ap.OutStreamer->EmitValueToAlignment(ap.getPointerSize());
	ap.OutStreamer->EmitLabel(sml_ftab);
#else
	ap.OutStreamer->emitValueToAlignment(ap.getPointerSize());
	ap.OutStreamer->emitLabel(sml_ftab);
#endif

	for (auto i = info.funcinfo_begin(); i != info.funcinfo_end(); ++i) {
		if ((*i)->getStrategy().getName() == getStrategy().getName())
			EmitFunctionInfo(ap, **i, sml_tabb);
#if LLVM_VERSION_MAJOR <= 10
		ap.OutStreamer->EmitValueToAlignment(ap.getPointerSize());
#else
		ap.OutStreamer->emitValueToAlignment(ap.getPointerSize());
#endif
	}
	EmitUInt16(ap, 0);
}
