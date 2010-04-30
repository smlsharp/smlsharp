                      case 0:
                        FRAME_ENTRY(SP, destination).uint32 =
                            ((CONVENTION UInt32Value (*)())function)();
                        break;
                      case 1:
                        FRAME_ENTRY(SP, destination).uint32 = 
                            ((CONVENTION UInt32Value (*)(UInt32Value))function)
                            (FRAME_ENTRY(SP, argIndexes[0]).uint32);
                        break;
                      case 2:
                        FRAME_ENTRY(SP, destination).uint32 = 
                            ((CONVENTION UInt32Value (*)(UInt32Value, UInt32Value))
                             function)
                            (FRAME_ENTRY(SP, argIndexes[0]).uint32,
                             FRAME_ENTRY(SP, argIndexes[1]).uint32);
                        break;
                      case 3:
                        FRAME_ENTRY(SP, destination).uint32 = 
                            ((CONVENTION UInt32Value (*)
                               (UInt32Value, UInt32Value, UInt32Value))
                             function)
                            (FRAME_ENTRY(SP, argIndexes[0]).uint32,
                             FRAME_ENTRY(SP, argIndexes[1]).uint32,
                             FRAME_ENTRY(SP, argIndexes[2]).uint32);
                        break;
                      case 4:
                        FRAME_ENTRY(SP, destination).uint32 = 
                            ((CONVENTION UInt32Value (*)
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
                        FRAME_ENTRY(SP, destination).uint32 = 
                            ((CONVENTION UInt32Value (*)
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
                        FRAME_ENTRY(SP, destination).uint32 = 
                            ((CONVENTION UInt32Value (*)
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
                        FRAME_ENTRY(SP, destination).uint32 = 
                            ((CONVENTION UInt32Value (*)
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
                        FRAME_ENTRY(SP, destination).uint32 = 
                            ((CONVENTION UInt32Value (*)
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
                        FRAME_ENTRY(SP, destination).uint32 = 
                            ((CONVENTION UInt32Value (*)
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
                        FRAME_ENTRY(SP, destination).uint32 = 
                            ((CONVENTION UInt32Value (*)
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
