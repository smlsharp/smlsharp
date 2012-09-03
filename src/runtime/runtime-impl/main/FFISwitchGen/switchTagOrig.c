                      case 0:
                        returnValue.uint32 = ((UInt32Value (*)())function)();
                        break;
                      case 1:
                        returnValue.uint32 = 
                            ((UInt32Value (*)(UInt32Value))function)
                            (FRAME_ENTRY(SP, argIndexes[0]).uint32);
                        break;
                      case 2:
                        returnValue.uint32 = 
                            ((UInt32Value (*)(UInt32Value, UInt32Value))
                             function)
                            (FRAME_ENTRY(SP, argIndexes[0]).uint32,
                             FRAME_ENTRY(SP, argIndexes[1]).uint32);
                        break;
                      case 3:
                        returnValue.uint32 = 
                            ((UInt32Value (*)
                               (UInt32Value, UInt32Value, UInt32Value))
                             function)
                            (FRAME_ENTRY(SP, argIndexes[0]).uint32,
                             FRAME_ENTRY(SP, argIndexes[1]).uint32,
                             FRAME_ENTRY(SP, argIndexes[2]).uint32);
                        break;
                      case 4:
                        returnValue.uint32 = 
                            ((UInt32Value (*)
                               (UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value))
                             function)
                            (FRAME_ENTRY(SP, argIndexes[0]).uint32,
                             FRAME_ENTRY(SP, argIndexes[1]).uint32,
                             FRAME_ENTRY(SP, argIndexes[2]).uint32,
                             FRAME_ENTRY(SP, argIndexes[3]).uint32);
                        break;
                      case 5:
                        returnValue.uint32 = 
                            ((UInt32Value (*)
                               (UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value))
                             function)
                            (FRAME_ENTRY(SP, argIndexes[0]).uint32,
                             FRAME_ENTRY(SP, argIndexes[1]).uint32,
                             FRAME_ENTRY(SP, argIndexes[2]).uint32,
                             FRAME_ENTRY(SP, argIndexes[3]).uint32,
                             FRAME_ENTRY(SP, argIndexes[4]).uint32);
                        break;
                      case 6:
                        returnValue.uint32 = 
                            ((UInt32Value (*)
                               (UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value))
                             function)
                            (FRAME_ENTRY(SP, argIndexes[0]).uint32,
                             FRAME_ENTRY(SP, argIndexes[1]).uint32,
                             FRAME_ENTRY(SP, argIndexes[2]).uint32,
                             FRAME_ENTRY(SP, argIndexes[3]).uint32,
                             FRAME_ENTRY(SP, argIndexes[4]).uint32,
                             FRAME_ENTRY(SP, argIndexes[5]).uint32);
                        break;
                      case 7:
                        returnValue.uint32 = 
                            ((UInt32Value (*)
                               (UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value))
                             function)
                            (FRAME_ENTRY(SP, argIndexes[0]).uint32,
                             FRAME_ENTRY(SP, argIndexes[1]).uint32,
                             FRAME_ENTRY(SP, argIndexes[2]).uint32,
                             FRAME_ENTRY(SP, argIndexes[3]).uint32,
                             FRAME_ENTRY(SP, argIndexes[4]).uint32,
                             FRAME_ENTRY(SP, argIndexes[5]).uint32,
                             FRAME_ENTRY(SP, argIndexes[6]).uint32);
                        break;
                      case 8:
                        returnValue.uint32 = 
                            ((UInt32Value (*)
                               (UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value))
                             function)
                            (FRAME_ENTRY(SP, argIndexes[0]).uint32,
                             FRAME_ENTRY(SP, argIndexes[1]).uint32,
                             FRAME_ENTRY(SP, argIndexes[2]).uint32,
                             FRAME_ENTRY(SP, argIndexes[3]).uint32,
                             FRAME_ENTRY(SP, argIndexes[4]).uint32,
                             FRAME_ENTRY(SP, argIndexes[5]).uint32,
                             FRAME_ENTRY(SP, argIndexes[6]).uint32,
                             FRAME_ENTRY(SP, argIndexes[7]).uint32);
                        break;
                      case 9:
                        returnValue.uint32 = 
                            ((UInt32Value (*)
                               (UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value))
                             function)
                            (FRAME_ENTRY(SP, argIndexes[0]).uint32,
                             FRAME_ENTRY(SP, argIndexes[1]).uint32,
                             FRAME_ENTRY(SP, argIndexes[2]).uint32,
                             FRAME_ENTRY(SP, argIndexes[3]).uint32,
                             FRAME_ENTRY(SP, argIndexes[4]).uint32,
                             FRAME_ENTRY(SP, argIndexes[5]).uint32,
                             FRAME_ENTRY(SP, argIndexes[6]).uint32,
                             FRAME_ENTRY(SP, argIndexes[7]).uint32,
                             FRAME_ENTRY(SP, argIndexes[8]).uint32);
                        break;
                      case 10:
                        returnValue.uint32 = 
                            ((UInt32Value (*)
                               (UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value,
                                UInt32Value))
                             function)
                            (FRAME_ENTRY(SP, argIndexes[0]).uint32,
                             FRAME_ENTRY(SP, argIndexes[1]).uint32,
                             FRAME_ENTRY(SP, argIndexes[2]).uint32,
                             FRAME_ENTRY(SP, argIndexes[3]).uint32,
                             FRAME_ENTRY(SP, argIndexes[4]).uint32,
                             FRAME_ENTRY(SP, argIndexes[5]).uint32,
                             FRAME_ENTRY(SP, argIndexes[6]).uint32,
                             FRAME_ENTRY(SP, argIndexes[7]).uint32,
                             FRAME_ENTRY(SP, argIndexes[8]).uint32,
                             FRAME_ENTRY(SP, argIndexes[9]).uint32);
                        break;
                      default:
                        DBGWRAP
                        (printf
                         ("Error: too many arguments %d\n", argsCount);)
                        throw IllegalStateException();
                        break;
                    }
                    UInt32Value destination = getWordAndInc(PC);
                    FRAME_ENTRY(SP, destination) = returnValue;
                    break;
