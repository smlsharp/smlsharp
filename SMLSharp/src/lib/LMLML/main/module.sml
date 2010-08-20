(*
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)

use "./CODECS.sig";
use "./Codecs.sml";

use "./MULTI_BYTE_CHAR.sig";
use "./MULTI_BYTE_STRING.sig";
use "./MULTI_BYTE_SUBSTRING.sig";
use "./MULTI_BYTE_PARSER_COMBINATOR.sig";
use "./MULTI_BYTE_STRING_CONVERTER.sig";
use "./MULTI_BYTE_TEXT.sig";

use "./PRIM_CODEC.sig";
use "./CodecStringBase.sml";
use "./CodecCharBase.sml";
use "./CodecSubstringBase.sml";
use "./CodecStringConverterBase.sml";
use "./CodecParserCombinatorBase.sml";
use "./CODEC.sig";
use "./Codec.sml";

use "./PrimCodecUtil.sml";
use "./VariableLengthCharPrimCodecBase.sml";
use "./FixedLengthCharPrimCodecBase.sml";

use "./ASCIICodec.sml";
use "./EUCJPCodec.sml";
use "./GBKCodec.sml";
use "./GB2312Codec.sml";
use "./ISO2022JPCodec.sml";
use "./ShiftJISCodec.sml";
use "./UTF8Codec.sml";
use "./UTF16Codec.sml";

use "./MultiByteText.sml";

(*
use "./IConvFFI_${OS}.sml";
use "./IConv.sml";
*)