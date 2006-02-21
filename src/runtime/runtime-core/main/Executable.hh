#ifndef Executable_hh_
#define Executable_hh_

#include "SystemDef.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/**
 * This data structure contains VM instructions sequence.
 *
 */
struct Executable
{
    typedef enum _ByteOrder
    {
        LittleEndian = 0,
        BigEndian = 1
    } ByteOrder;

    /**
     * the endian of the multi byte operands in the code
     */
    UInt8Value byteOrder_;

    /**
     * the number of 32bit words of the executable.
     * Sizes of <code>code</code> and other informations are included.
     */
    UInt32Value totalWordLength_;

    /**
     * the buffer which include code and other informations.
     */
    UInt32Value* buffer_;

    /**
     * the number of 32bit words of the <code>code</code>
     * Until linked by ExecutableLinker, this is zero.
     */
    UInt32Value codeWordLength_;

    /**
     * the VM instruction sequence
     */
    UInt32Value* code_;

    /**
     * the number of entries in <code>locations</code>.
     */
    UInt32Value locationsCount_;
    /**
     * a pointer to a sequence of locationEntries which are in serialized form.
     */
    UInt32Value* locations_;

    /**
     * the number of pointers in </code>fileNames</code>.
     */
    UInt32Value fileNamesCount_;
    /**
     * a pointer to a sequence of pointers to <code>fileName</code>.
     * <pre>struct fileName {UInt32Value length; char* string}</pre>.
     */
    void **fileNames_;


    /**
     * the number of entries in <code>nameSlots</code>.
     */
    UInt32Value nameSlotsCount_;
    /**
     * a pointer to a sequence of nameSlotEntries which are in serialized form.
     */
    UInt32Value* nameSlots_;

    /**
     * the number of pointers in </code>boundNames</code>.
     */
    UInt32Value boundNamesCount_;
    /**
     * a pointer to a sequence of pointers to <code>boundName</code>.
     * <pre>struct boundName {UInt32Value length; char* string}</pre>.
     */
    void **boundNames_;

    /**
     * constructor
     */
    Executable(UInt32Value l, UInt32Value* c)
        : byteOrder_(NATIVE_BYTE_ORDER),
          totalWordLength_(l),
          buffer_(c),
          codeWordLength_(0),
          code_(0),
          locationsCount_(0),
          locations_(0),
          fileNamesCount_(0),
          fileNames_(0),
          nameSlotsCount_(0),
          nameSlots_(0),
          boundNamesCount_(0),
          boundNames_(0)
    {}

    /**
     * constructor
     */
    Executable(ByteOrder b, UInt32Value l, UInt32Value* c)
        : byteOrder_(b),
          totalWordLength_(l),
          buffer_(c),
          codeWordLength_(0),
          code_(0),
          locationsCount_(0),
          locations_(0),
          fileNamesCount_(0),
          fileNames_(0),
          nameSlotsCount_(0),
          nameSlots_(0),
          boundNamesCount_(0),
          boundNames_(0)
    {}

};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // Executable_hh_
