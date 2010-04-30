#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

#include <stdio.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

void 
IMLPrim_Char_chrImpl(UInt32Value argsCount,
                     Cell* argumentRefs[],
                     Cell* resultRef)
{
    *resultRef = *argumentRefs[0];
    return;
}

void
IMLPrim_Char_ordImpl(UInt32Value argsCount,
                     Cell* argumentRefs[],
                     Cell* resultRef)
{
    resultRef->sint32 = 0xFF & argumentRefs[0]->uint32;
    return;
}

void 
IMLPrim_Char_toStringImpl(UInt32Value argsCount,
                          Cell* argumentRefs[],
                          Cell* resultRef)
{
    // assume single byte character only
    char buffer[2];
    buffer[0] = argumentRefs[0]->uint32;
    buffer[1] = 0;
    *resultRef = PrimitiveSupport::stringToCell(buffer, 1);
    return;
};

void
IMLPrim_Char_toEscapedStringImpl(UInt32Value argsCount,
                                 Cell* argumentRefs[],
                                 Cell* resultRef)
{
    // converts a char to an escaped string as Char.toString of SML Basis.
    // assume single byte character only
    char* string = 0;
    char buffer[7];

    UInt32Value ch = argumentRefs[0]->uint32;
    switch(ch){
    case '\\': {string = "\\\\"; break;}
    case '"': {string = "\\\""; break;}
    case '\a': {string = "\\a"; break;}
    case '\b': {string = "\\b"; break;}
    case '\t': {string = "\\t"; break;}
    case '\n': {string = "\\n"; break;}
    case '\v': {string = "\\v"; break;}
    case '\f': {string = "\\f"; break;}
    case '\r': {string = "\\r"; break;}
    default:
      {
	if(ch < 32){
	  sprintf(buffer, "\\^%c", ch + 64);
	}
	else if(999 < ch){
	  sprintf(buffer, "\\u%0.4X", ch);
	}
	else if(126 < ch){
	  sprintf(buffer, "\\%.3d", ch);
	}
	else{
	  // printable characters.
	  buffer[0] = ch;
	  buffer[1] = 0;
	}
	string = buffer;
	break;
      }
    }
    *resultRef = PrimitiveSupport::stringToCell(string);
    return;
};

Primitive IMLPrim_Char_chr = IMLPrim_Char_chrImpl;
Primitive IMLPrim_Char_ord = IMLPrim_Char_ordImpl;
Primitive IMLPrim_Char_toString = IMLPrim_Char_toStringImpl;
Primitive IMLPrim_Char_toEscapedString = IMLPrim_Char_toEscapedStringImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
