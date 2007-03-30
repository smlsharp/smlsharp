#include <windows.h>
#include <stdio.h>
#include <assert.h>
#include <iostream>
#include <sstream>
#include <fstream>
#include <list>
#include <set>

/**
 * Generator of SML wrapper code for COM/OLE objects.
 *
 * To compile this code on Cygwin or MinGW, 
 *   $ g++ -o OLE2SML.exe OLEToSML.cc -loleaut32 -lole32 -luuid
 *
 * Usage:
 *   $ OLE.exe [options] TYPELIB_FILENAME
 *   $ OLE.exe [options] ProgID
 *
 * Options:
 *   -c CLASSNAME   generates wrapper codes for specified classes only.
 *                 You can use this option more than once.
 *                 If no -c option is specified, wrappers for all classes are
 *                 generated.
 *   -o FILENAME    writes wrapper code into the specified file name.
 *                 If no -o option is specified, file name is TYPELIBNAME.sml .
 *
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OLE2SML.cc,v 1.24 2007/03/15 03:48:32 kiyoshiy Exp $
 */

///////////////////////////////////////////////////////////////////////////////
// Type definitions

typedef std::list<std::string> StringList;
typedef std::set<std::string> StringSet;
typedef std::list<ITypeInfo*> TypeInfoList;

class Unsupported
{
  private:
    std::string description_;
  public:
    Unsupported(std::string description)
        : description_(description)
    {
    }
    std::string description(){return description_;}
};

///////////////////////////////////////////////////////////////////////////////
// Variables.

const std::string Keywords[] =
{
    /* keywords of SML core language. */
    "abstype",
    "and",
    "andalso",
    "as",
    "case",
    "datatype",
    "do",
    "else",
    "end",
    "exception",
    "fn",
    "fun",
    "handle",
    "if",
    "in",
    "infix",
    "infixr",
    "let",
    "local",
    "nonfix",
    "of",
    "op",
    "open",
    "orelse",
    "raise",
    "rec",
    "then",
    "type",
    "val",
    "with",
    "withtype",
    "while",

    /* keywords of SML module language. */
    "eqtype",
    "functor",
    "include",
    "sharing",
    "sig",
    "signature",
    "struct",
    "structure",
    "where",
};

StringSet KeywordsSet(&Keywords[0], &Keywords[sizeof(Keywords) / sizeof(Keywords[0])]);

///////////////////////////////////////////////////////////////////////////////
// Functions.

////////////////////////////////////////
// SML Common utilities

bool isSMLKeyword(std::string string)
{
    return (KeywordsSet.end() != KeywordsSet.find(string));
}

std::string SMLID(std::string name)
{
    // ML identifier of type, variable and structure must start.
    if(!isalnum(name[0])){
        name = 'x' + name + '\'';
    }
    if(isSMLKeyword(name)){
        name += '\'';
    }
    return name;
}

////////////////////////////////////////
// OLE Common utilities

void CHECKRESULT(HRESULT hresult)
{
    if(hresult != NOERROR && FAILED(GetScode(hresult)))
    {
        TCHAR* buffer;
        FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM
                      | FORMAT_MESSAGE_ALLOCATE_BUFFER,
                      NULL,
                      hresult,
                      MAKELANGID(LANG_NEUTRAL, SUBLANG_NEUTRAL),
                      (LPTSTR)&buffer,
                      0,
                      NULL);
        printf("COMERROR:%s\n", buffer);
        LocalFree(buffer);
        exit(-1);
    }
}

std::string BSTRToANSI(BSTR bstr)
{
    char ansi[MAX_PATH];// ToDo : 
    int bstrLen = SysStringLen(bstr);
    if(0 == bstrLen){return "";}
    WideCharToMultiByte(CP_ACP, 0, bstr, bstrLen + 1, ansi, MAX_PATH, 0, 0);
    return std::string(ansi);
}

TYPEKIND typekindOfTypeInfo(ITypeInfo* pTypeInfo)
{
    TYPEATTR* pTypeAttr;
    CHECKRESULT(pTypeInfo->GetTypeAttr(&pTypeAttr));
    TYPEKIND kind = pTypeAttr->typekind;
    pTypeInfo->ReleaseTypeAttr(pTypeAttr);
    return kind;
}

ITypeInfo* findDefaultInterface(ITypeInfo* pTypeInfo)
{
    ITypeInfo* pDefaultInterface = NULL;
    TYPEATTR* pTypeAttr;
    CHECKRESULT(pTypeInfo->GetTypeAttr(&pTypeAttr));
    if(TKIND_DISPATCH == pTypeAttr->typekind){
        pDefaultInterface = pTypeInfo;
        pTypeInfo->AddRef();
    }
    for(int i = 0;
        NULL == pDefaultInterface && i < pTypeAttr->cImplTypes;
        i += 1)
    {
        HREFTYPE refType;
        ITypeInfo* pInterface;
        CHECKRESULT(pTypeInfo->GetRefTypeOfImplType(i, &refType));
        CHECKRESULT(pTypeInfo->GetRefTypeInfo(refType, &pInterface));
        int implTypeFlags;
        CHECKRESULT(pTypeInfo->GetImplTypeFlags(i, &implTypeFlags));
        if(TKIND_DISPATCH == typekindOfTypeInfo(pInterface)
           && (IMPLTYPEFLAG_FDEFAULT & implTypeFlags)
           && !(IMPLTYPEFLAG_FSOURCE & implTypeFlags))
        {
            pDefaultInterface = pInterface;
            pInterface->AddRef();
        }
        pInterface->Release();
    }
    pTypeInfo->ReleaseTypeAttr(pTypeAttr);

    if(pDefaultInterface){return pDefaultInterface;}
    else{return pTypeInfo;}
}

std::string getTypeInfoName(ITypeInfo* pTypeInfo)
{
    BSTR bstrName;
    CHECKRESULT(pTypeInfo->GetDocumentation(MEMBERID_NIL,
                                            &bstrName,
                                            NULL,
                                            NULL,
                                            NULL));
    std::string className = BSTRToANSI(bstrName);
    SysFreeString(bstrName);
    return className;
}

std::string getTypeLibName(ITypeLib* pTypeLib)
{
    BSTR bstrName;
    CHECKRESULT(pTypeLib->GetDocumentation(-1,
                                           &bstrName,
                                           NULL,
                                           NULL,
                                           NULL));
    std::string libName = BSTRToANSI(bstrName);
    SysFreeString(bstrName);
    return libName;
}

std::string getTypeInfoMemberName(ITypeInfo* pTypeInfo, MEMBERID memid)
{
    BSTR name;
    UINT cNames;
    CHECKRESULT(pTypeInfo->GetNames(memid, &name, 1, &cNames));
    return BSTRToANSI(name);
}

std::string getTypeInfoDoc(ITypeInfo* pTypeInfo)
{
    BSTR bstrDoc;
    CHECKRESULT(pTypeInfo->GetDocumentation(MEMBERID_NIL,
                                            NULL,
                                            &bstrDoc,
                                            NULL,
                                            NULL));
    std::string doc = BSTRToANSI(bstrDoc);
    SysFreeString(bstrDoc);
    return doc;
}

std::string getTypeLibDoc(ITypeLib* pTypeLib)
{
    BSTR bstrDoc;
    CHECKRESULT(pTypeLib->GetDocumentation(-1,
                                           NULL,
                                           &bstrDoc,
                                           NULL,
                                           NULL));
    std::string doc = BSTRToANSI(bstrDoc);
    SysFreeString(bstrDoc);
    return doc;
}

std::string getTypeInfoMemberDoc(ITypeInfo* pTypeInfo, MEMBERID memid)
{
    BSTR bstrDoc;
    CHECKRESULT(pTypeInfo->GetDocumentation(memid,
                                            NULL,
                                            &bstrDoc,
                                            NULL,
                                            NULL));
    std::string doc = BSTRToANSI(bstrDoc);
    SysFreeString(bstrDoc);
    return doc;
}

////////////////////////////////////////
// OLE2SML specific utility functions

std::string SMLDocComment(std::string description)
{
    if(description.empty()){return "";}
    return ("(**\n"
            " * " + description + "\n"
            " *)\n");
}

std::string TYPEKINDString(TYPEKIND kind)
{
    switch(kind){
      case TKIND_ENUM: return "ENUM";
      case TKIND_RECORD: return "RECORD";
      case TKIND_MODULE: return "MODULE";
      case TKIND_INTERFACE: return "INTERFACE";
      case TKIND_DISPATCH: return "DISPATCH";
      case TKIND_COCLASS: return "COCLASS";
      case TKIND_ALIAS: return "ALIAS";
      case TKIND_UNION: return "UNION";
      default: throw Unsupported("unknown TYPEKIND");
    }
}

std::string TYPEDESCString(ITypeInfo* pti, TYPEDESC* typeDesc)
{
    std::ostringstream oss;
    if(typeDesc->vt == VT_PTR) {
        oss<< TYPEDESCString(pti, typeDesc->lptdesc)<< '*';
        return oss.str();
    }
    if(typeDesc->vt == VT_SAFEARRAY) {
        oss<< "SAFEARRAY("
           << TYPEDESCString(pti, typeDesc->lptdesc)<< ')';
        return oss.str();
    }
    if(typeDesc->vt == VT_CARRAY) {
        oss<< TYPEDESCString(pti, &typeDesc->lpadesc->tdescElem);
        for(int dim(0); typeDesc->lpadesc->cDims; ++dim) 
        oss<< '['<< typeDesc->lpadesc->rgbounds[dim].cElements<< ']';
        return oss.str();
    }
    if(typeDesc->vt == VT_USERDEFINED) {
        ITypeInfo* pRefTypeInfo;
        CHECKRESULT(pti->GetRefTypeInfo(typeDesc->hreftype, &pRefTypeInfo));
        std::string refTypeName = getTypeInfoName(pRefTypeInfo);
        return ("USERDEFINED("
                + TYPEKINDString(typekindOfTypeInfo(pRefTypeInfo))
                + ":" + refTypeName + ")");
/*
        oss<< TYPEDESCString(pti, typeDesc->hreftype);
        return oss.str();
*/
    }
        
    switch(typeDesc->vt) {
        // VARIANT compatible types
      case VT_I2: return "I2";
      case VT_I4: return "I4";
      case VT_R4: return "R4";
      case VT_R8: return "R8";
      case VT_CY: return "CY";
      case VT_DATE: return "DATE";
      case VT_BSTR: return "BSTR";
      case VT_DISPATCH: return "DISPATCH";
      case VT_ERROR: return "ERROR";
      case VT_BOOL: return "BOOL";
      case VT_VARIANT: return "VARIANT";
      case VT_UNKNOWN: return "UNKNOWN";
      case VT_UI1: return "UI1";
        // VARIANTARG compatible types
      case VT_DECIMAL: return "DECIMAL";
      case VT_I1: return "I1";
      case VT_UI2: return "UI2";
      case VT_UI4: return "UI4";
      case VT_I8: return "I8";
      case VT_UI8: return "UI8";
      case VT_INT: return "INT";
      case VT_UINT: return "UINT";
      case VT_HRESULT: return "HRESULT";
      case VT_VOID: return "VOID";
      case VT_LPSTR: return "LPSTR";
      case VT_LPWSTR: return "LPWSTR";
    }
    return "BIG ERROR!";
}

std::string VARTYPEString(VARTYPE vt)
{
    std::string suffix;

    if(vt & VT_BYREF){
        vt &= ~VT_BYREF;
        suffix = "*";
    }
    if(vt & VT_ARRAY){
        vt &= ~VT_ARRAY;
        suffix = "[]";
    }

    std::string ty;
    switch(vt) {
        // VARIANT compatible types
      case VT_I2: ty = "I2"; break;
      case VT_I4: ty = "I4"; break;
      case VT_R4: ty = "R4"; break;
      case VT_R8: ty = "R8"; break;
      case VT_CY: ty = "CY"; break;
      case VT_DATE: ty = "DATE"; break;
      case VT_BSTR: ty = "BSTR"; break;
      case VT_DISPATCH: ty = "DISPATCH"; break;
      case VT_ERROR: ty = "ERROR"; break;
      case VT_BOOL: ty = "BOOL"; break;
      case VT_VARIANT: ty = "VARIANT"; break;
      case VT_UNKNOWN: ty = "UNKNOWN"; break;
      case VT_UI1: ty = "UI1"; break;
        // VARIANTARG compatible types
      case VT_DECIMAL: ty = "DECIMAL"; break;
      case VT_I1: ty = "I1"; break;
      case VT_UI2: ty = "UI2"; break;
      case VT_UI4: ty = "UI4"; break;
      case VT_I8: ty = "I8"; break;
      case VT_UI8: ty = "UI8"; break;
      case VT_INT: ty = "INT"; break;
      case VT_UINT: ty = "UINT"; break;
      case VT_HRESULT: ty = "HRESULT"; break;
      case VT_VOID: ty = "VOID"; break;
      case VT_LPSTR: ty = "LPSTR"; break;
      case VT_LPWSTR: ty = "LPWSTR"; break;
      default:
        return "BIG ERROR!";
    }
    return ty + suffix;
}

std::string MLLiteralOfVariant(VARIANT* variant)
{
    std::ostringstream oss;

    switch(V_VT(variant)){
//      case VT_EMPTY: break;
//      case VT_NULL: break;
//      case VT_I2: oss << V_I2(variant); break;
      case VT_I4: 
        oss << (V_I4(variant) < 0 ? "~" : "") << abs(V_I4(variant)); break;
//      case VT_R4: oss << V_R4(variant); break;
//      case VT_R8: oss << V_R8(variant); break;
//      case VT_CY: oss << V_CY(variant); break;
//      case VT_DATE: oss << V_DATE(variant); break;
      case VT_BSTR: oss << "\"" << BSTRToANSI(V_BSTR(variant)) << "\""; break;
//      case VT_DISPATCH: oss << V_DISPATCH(variant); break;
//      case VT_ERROR: oss << V_ERROR(variant); break;
      case VT_BOOL: oss << (V_BOOL(variant) ? "true" : "false"); break;
//      case VT_VARIANT: oss << V_VARIANT(variant); break;
//      case VT_DECIMAL: oss << V_DECIMAL(variant); break;
//      case VT_RECORD: oss << V_RECORD(variant); break;
//      case VT_UNKNOWN: oss << V_UNKNOWN(variant); break;
      case VT_I1: oss << (unsigned int)(V_I1(variant)); break;
      case VT_UI1: oss << "0wx" << V_UI1(variant); break;
//      case VT_UI2: oss << V_UI2(variant); break;
      case VT_UI4: oss << "0wx" << V_UI4(variant); break;
//      case VT_INT:
//        oss << (V_INT(variant) < 0 ? "~" : "") << abs(V_INT(variant)); break;
//      case VT_UINT: oss << "0wx" << V_UINT(variant); break;
      default: throw Unsupported(VARTYPEString(V_VT(variant)));
    }
    return oss.str();
}

std::string stringCode(std::string string)
{
    return "(OLE.OLEString.fromAsciiString \"" + string + "\")";
}

std::string nameOfMethodWrapFunction(ITypeInfo* pTypeInfo, FUNCDESC* pFuncDesc)
{
    std::string memberName =
        getTypeInfoMemberName(pTypeInfo, pFuncDesc->memid);

    std::string funName;
    switch(pFuncDesc->invkind) {
      case INVOKE_PROPERTYGET: funName = "get"; break;
      case INVOKE_PROPERTYPUT: funName = "set"; break;
      case INVOKE_PROPERTYPUTREF: funName = "setRef"; break;
      case INVOKE_FUNC: funName = ""; break;
    }
    funName += memberName;
    return SMLID(funName);
}

////////////////////////////////////////

std::string MLTypeOfTYPEDESC(ITypeInfo* pTypeInfo, TYPEDESC* pTypeDesc)
{
    std::ostringstream oss;
    if(pTypeDesc->vt == VT_PTR) {
        /* ToDo : In OLE, it seems we can not pass a null pointer as a VT_PTR
         * parameter. Check it. */
        return MLTypeOfTYPEDESC(pTypeInfo, pTypeDesc->lptdesc);
    }
    if(pTypeDesc->vt == VT_SAFEARRAY) {
        if(VT_VARIANT == pTypeDesc->lptdesc->vt){
            return "(OLE.variant array * word list)";
        }
        throw Unsupported(TYPEDESCString(pTypeInfo, pTypeDesc));
/*
        oss << "SAFEARRAY("
            << dumpTypeDesc(pTypeInfo, pTypeDesc->lptdesc)
            << ')';
        return oss.str();
*/
    }
    if(pTypeDesc->vt == VT_USERDEFINED) {
        // support only user defined IDispatch interface.
        ITypeInfo* pRefTypeInfo;
        CHECKRESULT(pTypeInfo->GetRefTypeInfo(pTypeDesc->hreftype,
                                              &pRefTypeInfo));
        TYPEKIND RefTypeKind = typekindOfTypeInfo(pRefTypeInfo);
        if(TKIND_DISPATCH == RefTypeKind){
            return "OLE.Dispatch";
        }
        else if(TKIND_COCLASS == RefTypeKind){
            return "OLE.Dispatch";
        }
        else if(TKIND_ENUM == RefTypeKind){
            return "Int32.int";
        }
        else{
            throw Unsupported(TYPEDESCString(pTypeInfo, pTypeDesc));
        }
    }

    switch(pTypeDesc->vt) {
        // VARIANT compatible types
/*
      case VT_I2: return "short";
*/
      case VT_I4: return "Int32.int";
/*
      case VT_R4: return "float";
*/
      case VT_R8: return "Real64.real";
/*
      case VT_CY: return "CY";
      case VT_DATE: return "DATE";
*/
      case VT_BSTR: return "OLE.string";
      case VT_DISPATCH: return "OLE.Dispatch";
/*
      case VT_ERROR: return "SCODE";
*/
      case VT_BOOL: return "bool";
      case VT_VARIANT: return "OLE.variant";
      case VT_UNKNOWN: return "OLE.Unknown";
      case VT_UI1: return "Word8.word";
        // VARIANTARG compatible types
/*
      case VT_DECIMAL: return "DECIMAL";
*/
      case VT_I1: return "Word8.word";// ToDo : if we have Int8, use it.
/*
      case VT_UI2: return "USHORT";
*/
      case VT_UI4: return "Word32.word";
/*
      case VT_I8: return "__int64";
      case VT_UI8: return "unsigned __int64";
*/
      case VT_INT: return "Int32.int";
      case VT_UINT: return "Word32.word";
/*
      case VT_HRESULT: return "HRESULT";
*/
      case VT_VOID: return "unit";
/*
      case VT_LPSTR: return "char*";
      case VT_LPWSTR: return "wchar_t*";
*/
    }
    throw Unsupported(TYPEDESCString(pTypeInfo, pTypeDesc));
}

std::string toVariant(ITypeInfo* pTypeInfo, TYPEDESC* pTypeDesc)
{
    std::ostringstream oss;
    if(pTypeDesc->vt == VT_PTR) {
        if(VT_USERDEFINED == pTypeDesc->lptdesc->vt){
            return toVariant(pTypeInfo, pTypeDesc->lptdesc);
        }
        else{
            return
            "fromBYREF (" + toVariant(pTypeInfo, pTypeDesc->lptdesc) + ")";
        }
    }
    if(pTypeDesc->vt == VT_SAFEARRAY) {
        if(VT_VARIANT == pTypeDesc->lptdesc->vt){
            return "fromVARIANTARRAY";
        }
        throw Unsupported(TYPEDESCString(pTypeInfo, pTypeDesc));
/*
        oss << "SAFEARRAY("
            << dumpTypeDesc(pTypeInfo, pTypeDesc->lptdesc)
            << ')';
        return oss.str();
*/
    }
    if(pTypeDesc->vt == VT_USERDEFINED) {
        ITypeInfo* pRefTypeInfo;
        CHECKRESULT(pTypeInfo->GetRefTypeInfo(pTypeDesc->hreftype,
                                              &pRefTypeInfo));
        TYPEKIND RefTypeKind = typekindOfTypeInfo(pRefTypeInfo);
        if(TKIND_DISPATCH == RefTypeKind){
            return "fromDISPATCH";
        }
        else if(TKIND_COCLASS == RefTypeKind){
            return "fromDISPATCH";
        }
        else if(TKIND_ENUM == RefTypeKind){
            return "fromINT";
        }
        else{
            throw Unsupported(TYPEDESCString(pTypeInfo, pTypeDesc));
        }
    }

    switch(pTypeDesc->vt) {
        // VARIANT compatible types
/*
      case VT_I2: return "short";
*/
      case VT_I4: return "fromI4";
/*
      case VT_R4: return "float";
*/
      case VT_R8: return "fromR8";
/*
      case VT_CY: return "CY";
      case VT_DATE: return "DATE";
*/
      case VT_BSTR: return "fromBSTR";
      case VT_DISPATCH: return "fromDISPATCH";
/*
      case VT_ERROR: return "SCODE";
*/
      case VT_BOOL: return "fromBOOL";
      case VT_VARIANT: return "(fn x => x)"; // no wrap
      case VT_UNKNOWN: return "fromUNKNOWN";
      case VT_UI1: return "fromUI1";
        // VARIANTARG compatible types
/*
      case VT_DECIMAL: return "DECIMAL";
*/
      case VT_I1: return "fromI1";
/*
      case VT_UI2: return "USHORT";
*/
      case VT_UI4: return "fromUI4";
/*
      case VT_I8: return "__int64";
      case VT_UI8: return "unsigned __int64";
*/
      case VT_INT: return "fromINT";
      case VT_UINT: return "fromUINT";
/*
      case VT_HRESULT: return "HRESULT";
      case VT_VOID: return "unit";
      case VT_LPSTR: return "char*";
      case VT_LPWSTR: return "wchar_t*";
*/
    }
    throw Unsupported(TYPEDESCString(pTypeInfo, pTypeDesc));
}

std::string fromVariant(ITypeInfo* pTypeInfo, TYPEDESC* pTypeDesc)
{
    std::ostringstream oss;
    if(pTypeDesc->vt == VT_PTR) {
        if(VT_USERDEFINED == pTypeDesc->lptdesc->vt){
            return fromVariant(pTypeInfo, pTypeDesc->lptdesc);
        }
        else{
            return
            "toBYREF (" + fromVariant(pTypeInfo, pTypeDesc->lptdesc) + ")";
        }
    }
    if(pTypeDesc->vt == VT_SAFEARRAY) {
        if(VT_VARIANT == pTypeDesc->lptdesc->vt){
            return "toVARIANTARRAY";
        }
        throw Unsupported(TYPEDESCString(pTypeInfo, pTypeDesc));
/*
        oss << "SAFEARRAY("
            << dumpTypeDesc(pTypeInfo, pTypeDesc->lptdesc)
            << ')';
        return oss.str();
*/
    }
    if(pTypeDesc->vt == VT_USERDEFINED) {
        ITypeInfo* pRefTypeInfo;
        CHECKRESULT(pTypeInfo->GetRefTypeInfo(pTypeDesc->hreftype,
                                              &pRefTypeInfo));
        TYPEKIND RefTypeKind = typekindOfTypeInfo(pRefTypeInfo);
        if(TKIND_DISPATCH == RefTypeKind){
            return "toDISPATCH";
        }
        else if(TKIND_COCLASS == RefTypeKind){
            return "toDISPATCH";
        }
        else if(TKIND_ENUM == RefTypeKind){
            return "toINT";
        }
        else{
            throw Unsupported(TYPEDESCString(pTypeInfo, pTypeDesc));
        }
    }

    switch(pTypeDesc->vt) {
        // VARIANT compatible types
/*
      case VT_I2: return "short";
*/
      case VT_I4: return "toI4";
/*
      case VT_R4: return "float";
*/
      case VT_R8: return "toR8";
/*
      case VT_CY: return "CY";
      case VT_DATE: return "DATE";
*/
      case VT_BSTR: return "toBSTR";
      case VT_DISPATCH: return "toDISPATCH";
/*
      case VT_ERROR: return "SCODE";
*/
      case VT_BOOL: return "toBOOL";
      case VT_VARIANT: return "(fn x => x)";
      case VT_UNKNOWN: return "toUNKNOWN";
      case VT_UI1: return "toUI1";
        // VARIANTARG compatible types
/*
      case VT_DECIMAL: return "DECIMAL";
*/
      case VT_I1: return "toI1";
/*
      case VT_UI2: return "USHORT";
*/
      case VT_UI4: return "toUI4";
/*
      case VT_I8: return "__int64";
      case VT_UI8: return "unsigned __int64";
*/
      case VT_INT: return "toINT";
      case VT_UINT: return "toUINT";
/*
      case VT_HRESULT: return "HRESULT";
      case VT_VOID: return "unit";
      case VT_LPSTR: return "char*";
      case VT_LPWSTR: return "wchar_t*";
*/
    }
    throw Unsupported(TYPEDESCString(pTypeInfo, pTypeDesc));
}

std::string toVariant(ITypeInfo* pTypeInfo, ELEMDESC* pElemDesc)
{
    USHORT flags = pElemDesc->paramdesc.wParamFlags;
    if(flags & PARAMFLAG_FIN){
    }
    if(flags & PARAMFLAG_FOUT){
        throw Unsupported("PARAMFLAG_FOUT");
    }
    if(flags & PARAMFLAG_FRETVAL){
        throw Unsupported("PARAMFLAG_FRETVAL");
    }
    std::string function = toVariant(pTypeInfo, &pElemDesc->tdesc);
    if(flags & PARAMFLAG_FOPT){
        function = "optionalParam (" + function + ")";
    }
    return function;
}

std::string MLTypeOfELEMDESC(ITypeInfo* pTypeInfo, ELEMDESC* pElemDesc)
{
    std::ostringstream oss;
    USHORT flags = pElemDesc->paramdesc.wParamFlags;
    if(flags & PARAMFLAG_FIN){
    }
    if(flags & PARAMFLAG_FOUT){
        throw Unsupported("PARAMFLAG_FOUT");
    }
    if(flags & PARAMFLAG_FRETVAL){
        throw Unsupported("PARAMFLAG_FRETVAL");
    }
    if(flags & VARFLAG_FHIDDEN){
        throw Unsupported("VARFLAG_FHIDDEN");
    }
    if(flags & VARFLAG_FRESTRICTED){
        throw Unsupported("VARFLAG_FRESTRICTED");
    }
    if(flags & VARFLAG_FNONBROWSABLE){
        throw Unsupported("VARFLAG_FNONBROWSABLE");
    }

    oss << MLTypeOfTYPEDESC(pTypeInfo, &pElemDesc->tdesc);
    if(flags & PARAMFLAG_FOPT){
        oss << " option";
    }

    return oss.str();
}

std::string methodSignatureText(ITypeInfo* pTypeInfo, FUNCDESC* pFuncDesc)
{
    std::ostringstream oss;

/*
    oss << "[" << pFuncDesc->memid << "]";
*/

    oss << SMLDocComment(getTypeInfoMemberDoc(pTypeInfo, pFuncDesc->memid));
    oss << nameOfMethodWrapFunction(pTypeInfo, pFuncDesc) << " : ";

    if(0 == pFuncDesc->cParams){
        oss << "unit ";
    }
    else{
        oss << "(";
        for(int i = 0; i < pFuncDesc->cParams; i += 1){
            if(0 < i){oss << " * ";}
            oss << MLTypeOfELEMDESC(pTypeInfo,
                                    &pFuncDesc->lprgelemdescParam[i]);
        }
        oss << ")";
    }

    oss << " -> ";
    switch(pFuncDesc->invkind){
      case INVOKE_PROPERTYPUT:
      case INVOKE_PROPERTYPUTREF:
        oss << "unit"; break;
      default:
        oss << MLTypeOfTYPEDESC(pTypeInfo, &pFuncDesc->elemdescFunc.tdesc);
    }

    return oss.str();
}

std::string wrapMethodText(ITypeInfo* pTypeInfo, FUNCDESC* pFuncDesc)
{
    std::ostringstream oss;

    std::string funName = nameOfMethodWrapFunction(pTypeInfo, pFuncDesc);

    oss << "fun " << funName << " ";

    if(0 == pFuncDesc->cParams){
        oss << "()";
    }
    else{
        oss << "(";
        for(int i = 0; i < pFuncDesc->cParams; i += 1){
            if(0 < i){oss << ", ";}
            oss << "p" << i;
        }
        oss << ")";
    }
    oss << " = " << std::endl;

    oss << "  case ";

    switch(pFuncDesc->invkind){
      case INVOKE_PROPERTYPUT: oss << "#setByDISPID dispatch "; break;
      case INVOKE_PROPERTYPUTREF: oss << "#setRefByDISPID dispatch "; break;
      case INVOKE_PROPERTYGET: oss << "#getByDISPID dispatch "; break;
      case INVOKE_FUNC: oss << "#invokeByDISPID dispatch "; break;
    }
    // minus sign is "~" in SML code.
    if(0 <= pFuncDesc->memid){ oss << pFuncDesc->memid; }
    else{ oss << "~" << abs(pFuncDesc->memid); }

    /* A property put method takes a list of indexes and a new value of
     * the property separately.
     */
    int numParams;
    int numNamedParam;
    switch(pFuncDesc->invkind){
      case INVOKE_PROPERTYPUT: 
      case INVOKE_PROPERTYPUTREF:
        numParams = pFuncDesc->cParams - 1;// except new value of property
        break;
      default:
        numParams = pFuncDesc->cParams;
        break;
    }

    oss << " [";
    for(int i = 0; i < numParams; i += 1){
        if(0 < i){oss << ", ";}
        oss << toVariant(pTypeInfo, &pFuncDesc->lprgelemdescParam[i]);
        oss << " p" << i;
    }
    oss << "] ";

    if(numParams < pFuncDesc->cParams){// for Property put and putref
        oss << "("
            << toVariant(pTypeInfo, &pFuncDesc->lprgelemdescParam[numParams])
            << " p" << numParams
            << ")";
    }
    oss << std::endl;

    oss << "   of ";
    switch(pFuncDesc->invkind){
      case INVOKE_PROPERTYPUT: oss << "() => ()"; break;
      case INVOKE_PROPERTYPUTREF: oss << "() => ()"; break;
      case INVOKE_PROPERTYGET:
        {
            oss << " x => "
                << fromVariant(pTypeInfo, &pFuncDesc->elemdescFunc.tdesc)
                << " x"
                << std::endl;
            break;
        }
      case INVOKE_FUNC:
        if(VT_VOID == pFuncDesc->elemdescFunc.tdesc.vt){
            oss << "NONE => ()" << std::endl;
            oss << " | SOME _ => "
                << "raise OLE.OLEError"
                << "(OLE.ResultMismatch "
                << "\"" << funName << " returns unepxected SOME.\")"
                << std::endl;
        }
        else{
            oss << "SOME x => "
                << fromVariant(pTypeInfo, &pFuncDesc->elemdescFunc.tdesc)
                << " x" << std::endl;
            oss << "| NONE => raise OLE.OLEError"
                << "(OLE.ResultMismatch"
                << " \"" << funName << " does not return any value.\")"
                << std::endl;
        }
        break;
    }

    return oss.str();
}

std::string typeDefinitionText(ITypeInfo* pTargetTypeInfo)
{
    std::ostringstream oss;

    std::string typeName = SMLID(getTypeInfoName(pTargetTypeInfo));
    ITypeInfo* pTypeInfo = findDefaultInterface(pTargetTypeInfo);

    oss << SMLDocComment(getTypeInfoDoc(pTargetTypeInfo));
    oss << "type " << typeName << " = {"  << std::endl;
    oss << "(* interface " << typeName << " *)" << std::endl;

    TYPEATTR *pTypeAttr;
    CHECKRESULT(pTypeInfo->GetTypeAttr(&pTypeAttr));

    StringList funs;
    StringList errors;
    for(int i = 0; i < pTypeAttr->cFuncs; i+= 1){
        FUNCDESC* pFuncDesc;
        CHECKRESULT(pTypeInfo->GetFuncDesc(i, &pFuncDesc));
        std::string wrapFunName = nameOfMethodWrapFunction(pTypeInfo,
                                                           pFuncDesc);
        try{
            funs.push_back(methodSignatureText(pTypeInfo, pFuncDesc));
        }
        catch(Unsupported& e){
            errors.push_back("cannot convert "
                             + wrapFunName + ":" + e.description());
        }
        pTypeInfo->ReleaseFuncDesc(pFuncDesc);
    }
    // common methods.
    funs.push_back("this : unit -> OLE.Dispatch");
    funs.push_back("addRef : unit -> Word32.word");
    funs.push_back("release : unit -> Word32.word");

    for(StringList::iterator i = funs.begin(); i != funs.end(); i++)
    {
        if(i != funs.begin()){oss << ", " << std::endl;}
        oss << *i;
    }
    for(StringList::iterator i = errors.begin(); i != errors.end(); i++)
    {
        oss << std::endl;
        oss << "(* " << *i << " *)";
    }
    oss << std::endl << "};" << std::endl;

    pTypeInfo->ReleaseTypeAttr(pTypeAttr);
    pTypeInfo->Release();

    return oss.str();
}

std::string wrapFunText(ITypeInfo* pTargetTypeInfo)
{
    std::ostringstream oss;

    std::string typeName = SMLID(getTypeInfoName(pTargetTypeInfo));
    ITypeInfo* pTypeInfo = findDefaultInterface(pTargetTypeInfo);

    oss << "(* ---------------------------------------- *)" << std::endl;

    oss << "fun " << typeName << " (dispatch : OLE.Dispatch) = "
        << std::endl;
    oss << "(* interface " << typeName << " *)" << std::endl;

    StringList impls;
    StringList binds;
    StringList errors;
    TYPEATTR *pTypeAttr;
    CHECKRESULT(pTypeInfo->GetTypeAttr(&pTypeAttr));
    for(int i = 0; i < pTypeAttr->cFuncs; i+= 1){
        FUNCDESC* pFuncDesc;
        CHECKRESULT(pTypeInfo->GetFuncDesc(i, &pFuncDesc));
        std::string wrapFunName = nameOfMethodWrapFunction(pTypeInfo,
                                                           pFuncDesc);
        try{
            std::string impl = wrapMethodText(pTypeInfo, pFuncDesc);
            std::string bind = wrapFunName + " = " + wrapFunName;
            impls.push_back(impl);
            binds.push_back(bind);
        }
        catch(Unsupported& e){
            errors.push_back("cannot convert " + wrapFunName
                             +":" + e.description());
        }
        pTypeInfo->ReleaseFuncDesc(pFuncDesc);
    }
    // common methods.
    impls.push_back("fun this () = dispatch");
    impls.push_back("fun addRef () = (#addRef dispatch ()) : word");
    impls.push_back("fun release () = (#release dispatch ()) : word");
    binds.push_back("this = this");
    binds.push_back("addRef = addRef");
    binds.push_back("release = release");

    // generate function body.
    oss << "let" << std::endl;
    for(StringList::iterator i = impls.begin(); i != impls.end(); i++)
    {
        oss << *i << std::endl;
    }
    for(StringList::iterator i = errors.begin(); i != errors.end(); i++)
    {
        oss << "(* " << *i << " *)" << std::endl;
    }
    oss << "in" << std::endl;
    oss << " {" << std::endl;
    for(StringList::iterator i = binds.begin(); i != binds.end(); i++)
    {
        if(i != binds.begin()){oss << ", " << std::endl;}
        oss << *i;
    }
    oss << std::endl;
    oss << " } : " << typeName << std::endl;
    oss << "end" << std::endl;

    pTypeInfo->ReleaseTypeAttr(pTypeAttr);
    pTypeInfo->Release();

    return oss.str();
}

std::string wrapFunSignatureText(ITypeInfo* pTypeInfo)
{
    std::ostringstream oss;

    std::string typeName = SMLID(getTypeInfoName(pTypeInfo));

    oss << "(** " << std::endl;
    oss << " * cast an object to a " + typeName + "." << std::endl;
    oss << " *)" << std::endl;
    oss << "val " << typeName
        << " : OLE.Dispatch -> " << typeName << std::endl;

    return oss.str();
}

std::string createFunSignatureText(ITypeInfo* pTypeInfo)
{
    std::ostringstream oss;

    std::string typeName = SMLID(getTypeInfoName(pTypeInfo));

    oss << "(** " << std::endl;
    oss << " * create a " + typeName + " object." << std::endl;
    oss << " *)" << std::endl;
    oss << "val new" << typeName
        << " : unit -> " << typeName << std::endl;

    return oss.str();
}

std::string createFunText(ITypeInfo* pTypeInfo)
{
    std::ostringstream oss;

    std::string typeName = SMLID(getTypeInfoName(pTypeInfo));

    TYPEATTR* pTypeAttr;
    CHECKRESULT(pTypeInfo->GetTypeAttr(&pTypeAttr));
    LPOLESTR CLSIDOLESTR;
    CHECKRESULT(StringFromCLSID(pTypeAttr->guid, &CLSIDOLESTR));
    char ansiClsid[39];
    WideCharToMultiByte(CP_ACP, 0, CLSIDOLESTR, 39, ansiClsid, 39, 0, 0);
    std::string CLSIDString = ansiClsid;
    CoTaskMemFree(CLSIDOLESTR);
    pTypeInfo->ReleaseTypeAttr(pTypeAttr);

    oss << "fun new" << typeName << " () = " << std::endl;
    oss << "let val dispatch = "
        << "OLE.createInstanceOfCLSID "
        << stringCode(CLSIDString) << std::endl;
    oss << "in " << typeName << " dispatch" << std::endl;
    oss << "end" << std::endl;

    return oss.str();
}

void emitForConstantVar(ITypeInfo* pTypeInfo,
                        VARDESC* pVarDesc,
                        std::ostringstream& signature,
                        std::ostringstream& definition)
{
    std::string name =
        SMLID(getTypeInfoMemberName(pTypeInfo, pVarDesc->memid));
    try{
        std::string type = MLTypeOfELEMDESC(pTypeInfo, &pVarDesc->elemdescVar);
        std::string value = MLLiteralOfVariant(pVarDesc->lpvarValue);
        signature << SMLDocComment(getTypeInfoMemberDoc(pTypeInfo,
                                                        pVarDesc->memid));
        signature << "val " << name << " : " << type << std::endl;
        definition << "val " << name << " = " << value << " : " << type
                   << std::endl;
    }
    catch(Unsupported& e){
        throw Unsupported(name + e.description());
    }
}

void emitForConstantVars(ITypeInfo* pTypeInfo,
                         std::ostringstream& signature,
                         std::ostringstream& definition)
{
    std::ostringstream sig;
    std::ostringstream def;

    TYPEATTR *pTypeAttr;
    CHECKRESULT(pTypeInfo->GetTypeAttr(&pTypeAttr));

    StringList vars;
    StringList errors;
    for(int i = 0; i < pTypeAttr->cVars; i+= 1)
    {
        VARDESC* pVarDesc;
        CHECKRESULT(pTypeInfo->GetVarDesc(i, &pVarDesc));
        if((pVarDesc->varkind == VAR_CONST) &&
           !(pVarDesc->wVarFlags &
             (VARFLAG_FHIDDEN | VARFLAG_FRESTRICTED | VARFLAG_FNONBROWSABLE)))
        {
            try{
                emitForConstantVar(pTypeInfo, pVarDesc, sig, def);
            }
            catch(Unsupported& e){
                sig << "(* " << e.description() << " *)" << std::endl;
            }
        }
        pTypeInfo->ReleaseVarDesc(pVarDesc);
    }

    signature << sig.str();
    definition << def.str();
}

const std::string HeaderBindings =
" fun toI4 (OLE.I4 int) = int \n\
    | toI4 _ = raise OLE.OLEError(OLE.TypeMismatch \"I4 expected\") \n\
  fun toR8 (OLE.R8 real) = real \n\
    | toR8 _ = raise OLE.OLEError(OLE.TypeMismatch \"R8 expected\") \n\
  fun toBSTR (OLE.BSTR string) = string \n\
    | toBSTR _ = raise OLE.OLEError(OLE.TypeMismatch \"BSTR expected\") \n\
  fun toDISPATCH (OLE.DISPATCH object) = object \n\
    | toDISPATCH _ = raise OLE.OLEError(OLE.TypeMismatch \"DISPATCH expected\") \n\
  fun toBOOL (OLE.BOOL bool) = bool \n\
    | toBOOL _ = raise OLE.OLEError(OLE.TypeMismatch \"BOOL expected\") \n\
  fun toVARIANT (OLE.VARIANT variant) = variant \n\
    | toVARIANT _ = raise OLE.OLEError(OLE.TypeMismatch \"VARIANT expected\") \n\
  fun toUNKNOWN (OLE.UNKNOWN unknown) = unknown \n\
    | toUNKNOWN _ = raise OLE.OLEError(OLE.TypeMismatch \"UNKNOWN expected\") \n\
  fun toI1 (OLE.I1 char) = char \n\
    | toI1 _ = raise OLE.OLEError(OLE.TypeMismatch \"I1 expected\") \n\
  fun toUI1 (OLE.UI1 byte) = byte \n\
    | toUI1 _ = raise OLE.OLEError(OLE.TypeMismatch \"UI1 expected\") \n\
  fun toUI4 (OLE.UI4 word) = word \n\
    | toUI4 _ = raise OLE.OLEError(OLE.TypeMismatch \"UI4 expected\") \n\
  fun toINT (OLE.INT int) = int \n\
    | toINT _ = raise OLE.OLEError(OLE.TypeMismatch \"INT expected\") \n\
  fun toUINT (OLE.UINT word) = word \n\
    | toUINT _ = raise OLE.OLEError(OLE.TypeMismatch \"UINT expected\") \n\
  fun toBYREF toelement (OLE.BYREF(v)) = toelement v \n\
    | toBYREF _ _ = raise OLE.OLEError(OLE.TypeMismatch \"BYREF expected\") \n\
  fun toVARIANTARRAY (OLE.VARIANTARRAY array) = array \n\
    | toVARIANTARRAY _ = raise OLE.OLEError(OLE.TypeMismatch \"VARIANTARRAY expected\") \n\
 \n\
  val fromI4 = OLE.I4 \n\
  val fromR8 = OLE.R8 \n\
  val fromBSTR = OLE.BSTR \n\
  val fromDISPATCH = OLE.DISPATCH \n\
  val fromBOOL = OLE.BOOL \n\
  val fromVARIANT = OLE.VARIANT \n\
  val fromUNKNOWN = OLE.UNKNOWN \n\
  val fromI1 = OLE.I1 \n\
  val fromUI1 = OLE.UI1 \n\
  val fromUI4 = OLE.UI4 \n\
  val fromINT = OLE.INT \n\
  val fromUINT = OLE.UINT \n\
  fun fromBYREF fromElement v = OLE.BYREF(fromElement v) \n\
  val fromVARIANTARRAY = OLE.VARIANTARRAY \n\
  fun optionalParam fromElement NONE = OLE.NOPARAM \n\
   |  optionalParam fromElement (SOME v) = fromElement v \n\
";


void emitForLibrary(ITypeLib* pTypeLib,
                    TypeInfoList& typeInfos,
                    std::ostringstream& signature,
                    std::ostringstream& definition)
{
    std::ostringstream sig;
    std::ostringstream def;

    std::string libName = SMLID(getTypeLibName(pTypeLib));

    sig << SMLDocComment(getTypeLibDoc(pTypeLib));
    sig << "signature " << libName << " = " << std::endl;
    sig << "sig" << std::endl;

    def << "structure " << libName << " : " << libName << " = " << std::endl;
    def << "struct" << std::endl;
    def << HeaderBindings << std::endl;

    for(TypeInfoList::iterator i = typeInfos.begin();
        i != typeInfos.end();
        i++)
    {
        ITypeInfo* pTypeInfo = *i;
        TYPEKIND TypeKind = typekindOfTypeInfo(pTypeInfo);

        switch(TypeKind){
          case TKIND_DISPATCH:
          case TKIND_COCLASS:
            std::string typeDefinition = typeDefinitionText(pTypeInfo);
            sig << typeDefinition;
            sig << wrapFunSignatureText(pTypeInfo);
            def << typeDefinition;
            def << wrapFunText(pTypeInfo);
            if(TKIND_COCLASS == TypeKind){
                sig << createFunSignatureText(pTypeInfo);
                def << createFunText(pTypeInfo);
            }
            break;
        }
        emitForConstantVars(pTypeInfo, sig, def);
    }
    sig << "end;" << std::endl;
    def << "end;" << std::endl;

    signature << sig.str();
    definition << def.str();
}

void collectTypeInfos(ITypeLib* pTypeLib,
                      StringSet& names,
                      TypeInfoList& typeInfos)
{
    UINT infoCount = pTypeLib->GetTypeInfoCount();
    for(int i = 0; i < infoCount; i += 1){

        TYPEKIND TKind;
        CHECKRESULT(pTypeLib->GetTypeInfoType(i, &TKind));
        switch(TKind){
          case TKIND_ENUM: break;
          case TKIND_RECORD: continue;
          case TKIND_MODULE: break;
          case TKIND_INTERFACE: continue;
          case TKIND_DISPATCH: break;
          case TKIND_COCLASS: break;
          case TKIND_ALIAS: continue;
          case TKIND_UNION: continue;
        }

        ITypeInfo* pTypeInfo;
        CHECKRESULT(pTypeLib->GetTypeInfo(i, &pTypeInfo));

        std::string name = getTypeInfoName(pTypeInfo);
        if((!names.empty()) && (names.find(name) == names.end())){continue;}

        typeInfos.push_back(pTypeInfo);// not release pTypeInfo
    }
}

void usage(const char* progName)
{
    fprintf(stderr, "%s [-c CLASSNAME] [-o FILENAME] TYPELIB", progName);
    exit(1);
}

int main(int argc, const char** argv)
{
    ITypeLib *pTypeLib = NULL;
    IDispatch* pIDispatch = NULL;
    CLSID CLSID;
    ITypeInfo* pTypeInfo = NULL;
    UINT index;
    const char* outputFileName = NULL;

    StringSet names;

    const char** nextArg = argv + 1;
    const char** lastArg = argv + argc;
    while(nextArg < lastArg){
        if(0 == strcmp("-c", *nextArg)){
            nextArg += 1;
            if(NULL == *nextArg){ usage(argv[0]); }
            names.insert(*nextArg);
        }
        else if(0 == strcmp("-o", *nextArg)){
            nextArg += 1;
            if(NULL == *nextArg){ usage(argv[0]); }
            outputFileName = *nextArg;
        }
        else if(0 == strcmp("-h", *nextArg)){
            usage(argv[0]);
        }
        else{
            break;
        }
        nextArg += 1;
    }
    if(NULL == *nextArg){ usage(argv[0]); }
    const char* aTypelibName = *nextArg;

    OLECHAR wTypelibName[MAX_PATH];
    mbstowcs(wTypelibName, aTypelibName, MAX_PATH);

    CHECKRESULT(CoInitializeEx(NULL, COINIT_MULTITHREADED));

    ////////////////////////////////////////
    // find ITypeLib

    // guessing file path of type library is specified.
  PHASE_1:
    if(SUCCEEDED(LoadTypeLibEx(wTypelibName, REGKIND_NONE, &pTypeLib))){
        goto GOT;
    }

  PHASE_2:
    // guessing ProgID is specified.
    if(FAILED(CLSIDFromProgID(wTypelibName, &CLSID))){ goto PHASE_3; }
//    std::cerr << "found progID" << std::endl;
    if(FAILED(CoCreateInstance(CLSID,
                               NULL,
                               CLSCTX_INPROC_SERVER | CLSCTX_LOCAL_SERVER,
                               IID_IDispatch,
                               (LPVOID*)&pIDispatch)))
    { goto PHASE_3; }
//    std::cerr << "created instance" << std::endl;
    if(FAILED(pIDispatch->GetTypeInfo(0, LOCALE_NEUTRAL, &pTypeInfo)))
    { goto PHASE_3; }
//    std::cerr << "found ITypeInfo" << std::endl;
    if(FAILED(pTypeInfo->GetContainingTypeLib(&pTypeLib, &index)))
    { goto PHASE_3; }
//    std::cerr << "found ITypeLib" << std::endl;
    goto GOT;

  PHASE_3:

    std::cerr << "cannot found TypeLib for " << aTypelibName << std::endl;
    return 1;

    ////////////////////////////////////////

  GOT:
    std::string structureName = SMLID(getTypeLibName(pTypeLib));
//    std::ostringstream oss;
//    std::ostream &oss = std::cout;
    std::string outputFileNameString =
    outputFileName ? outputFileName : (structureName + ".sml");
    std::fstream oss(outputFileNameString.c_str(), std::fstream::out);

    TypeInfoList typeInfos;
    collectTypeInfos(pTypeLib, names, typeInfos);

    oss << "(* generated by " << std::endl;
    for(int i = 0; i < argc; i += 1){
        oss << argv[i] << " ";
    }
    oss << std::endl;
    oss << " *)" << std::endl;

    std::ostringstream sig;
    std::ostringstream def;
    emitForLibrary(pTypeLib, typeInfos, sig, def);
    oss << sig.str();
    oss << def.str();

    std::cerr << "generated " << outputFileNameString << std::endl;

    // clean up
    for(TypeInfoList::iterator i = typeInfos.begin();
        i != typeInfos.end();
        i++)
    {
        (*i)->Release();
    }
    pTypeLib->Release();
    oss.close();
    CoUninitialize();

    return 0;
}
