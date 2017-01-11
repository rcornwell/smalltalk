/*
 * Smalltalk interpreter: Primitive Methods.
 *
 * Copyright 1999-2017 Richard P. Cornwell.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the the Artistic License (2.0). You may obtain a copy
 * of the full license at:
 *
 * http://www.perlfoundation.org/artistic_license_2_0
 *
 * Any use, modification, and distribution of the Standard or Modified
 * Versions is governed by this Artistic License. By using, modifying or
 * distributing the Package, you accept this license. Do not use, modify, or
 * distribute the Package, if you do not accept this license.
 *
 * If your Modified Version has been derived from a Modified Version made by
 * someone other than you, you are nevertheless required to ensure that your
 * Modified Version complies with the requirements of this license.
 *
 * This license does not grant you the right to use any trademark, service
 * mark, tradename, or logo of the Copyright Holder.
 *
 * Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
 * AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
 * YOUR LOCAL LAW.  UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
 * CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
 * CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $Id: primitive.h,v 1.6 2001/08/18 16:17:02 rich Exp rich $
 *
 * $Log: primitive.h,v $
 * Revision 1.6  2001/08/18 16:17:02  rich
 * Added primitives for largeinteger and graphics system.
 *
 * Revision 1.5  2001/01/17 01:40:54  rich
 * Added primitives to flush method cache.
 *
 * Revision 1.4  2000/08/20 00:10:12  rich
 * Added primitive to return number of bytecodes in method.
 *
 * Revision 1.3  2000/02/02 00:33:47  rich
 * Moved assitent functions to smallobjs.c
 *
 * Revision 1.2  2000/02/01 18:10:02  rich
 * Added code to display stack trace on error.
 * Added support for CompiledMethod class.
 * Added support for CharStream class.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

#define	primitiveAdd			  1
#define	primitiveSub			  2
#define	primitiveMult			  3
#define	primitiveDivide			  4
#define	primitiveMod			  5
#define	primitiveDiv			  6
#define	primitiveBitAnd			  7
#define	primitiveBitOr			  8
#define	primitiveBitXor			  9
#define	primitiveBitShift		 10
#define	primitiveEqual			 11
#define	primitiveNotEqual		 12
#define	primitiveLess			 13
#define	primitiveGreater		 14
#define	primitiveLessEqual		 15
#define	primitiveGreaterEqual		 16
#define	primitiveMakePoint		 17
#define	primitiveAsFloat		 18
#define	primitiveFloatAdd		 19
#define	primitiveFloatSub		 20
#define	primitiveFloatMult		 21
#define	primitiveFloatDivide		 22
#define	primitiveFloatEqual		 23
#define	primitiveFloatNotEqual		 24
#define	primitiveFloatLess		 25
#define	primitiveFloatGreater		 26
#define	primitiveFloatLessEqual		 27
#define	primitiveFloatGreaterEqual	 28
#define	primitiveFloatTruncate		 29
#define	primitiveFloatFractionPart	 30
#define	primitiveFloatExponent		 31
#define	primitiveFloatTimesTwoPower	 32
#define	primitiveFloatExp		 33
#define	primitiveFloatLn		 34
#define	primitiveFloatPow		 35
#define	primitiveFloatSqrt		 36
#define	primitiveFloatCeil		 37
#define	primitiveFloatFloor		 38
#define	primitiveFloatSin		 39
#define	primitiveFloatCos		 40
#define	primitiveFloatTan		 41
#define	primitiveFloatASin		 42
#define	primitiveFloatACos		 43
#define	primitiveFloatATan		 44
#define	primitiveLargeIntAdd		111
#define	primitiveLargeIntSub		112
#define	primitiveLargeIntMult		113
#define	primitiveLargeIntDivide		114
#define	primitiveLargeIntMod		115
#define	primitiveLargeIntDiv		116
#define	primitiveLargeIntBitAnd		117
#define	primitiveLargeIntBitOr		118
#define	primitiveLargeIntBitXor		119
#define	primitiveLargeIntBitShift	120
#define	primitiveLargeIntEqual		121
#define	primitiveLargeIntNotEqual	122
#define	primitiveLargeIntLess		123
#define	primitiveLargeIntGreater	124
#define	primitiveLargeIntLessEqual	125
#define	primitiveLargeIntGreaterEqual	126
#define	primitiveLargeIntNegated	137
#define primitiveAsLargeInt		127
#define	primitiveAt			 45
#define	primitivePutAt			 46
#define	primitiveSize			 47
#define	primitiveStringAt		 48
#define	primitiveStringAtPut		 49
#define	primitiveNext			 50
#define	primitiveNextPut		 51
#define	primitiveAtEnd			 52
#define	primitiveObjectAt		 53
#define	primitiveObjectAtPut		 54
#define	primitiveNew			 55
#define	primitiveNewWithArg		 56
#define	primitiveBecome			 57
#define	primitiveInstVarAt		 58
#define	primitiveInstVarPutAt		 59
#define	primitiveAsOop			 60
#define	primitiveAsObject		 61
#define	primitiveSomeInstance		 62
#define	primitiveNextInstance		 63
#define	primitiveNewMethod		 64
#define	primitiveValue			 65
#define	primitiveValueWithArgs		 66
#define	primitivePreform		 67
#define	primitivePreformWithArgs	 68
#define	primitiveEquivalence		 69
#define	primitiveClass			 70
#define	primitiveSignal			 71
#define	primitiveWait			 72
#define	primitiveResume			 73
#define	primitiveSuspend		 74
#define	primitiveCoreUsed		 75
#define	primitiveFreeCore		 76
#define	primitiveOopsLeft		 77
#define	primitiveQuit			 78
#define	primitiveSnapShot		 79
#define	primitiveFileOpen		 80
#define	primitiveFileClose		 81
#define	primitiveFileSeek		 82
#define	primitiveFileTell		 83
#define	primitiveFileNext		 84
#define	primitiveFileNextPut		 85
#define	primitiveFileNextAll		 86
#define	primitiveFileNextPutAll		 87
#define	primitiveFileSize		 88
#define	primitiveFileAtEnd		 89
#define	primitiveFileDir		 90
#define primitiveFileisDirectory	108
#define primitiveFileRename		109
#define primitiveFileDelete		110
#define primitiveInternString		 91
#define primitiveClassComment		 92
#define primitiveMethodsFor		 93
#define primitiveError		 	 94
#define primitiveDumpObject		 95
#define primitiveSecondClock		 96
#define primitiveMillisecondClock	 97
#define primitiveSignalAtTick		 98
#define primitiveStackTrace		 99
#define primitiveEvaluate		100
#define primitiveFillBuffer		101
#define primitiveFlushBuffer		102
#define primitiveByteAt			103
#define primitiveByteAtPut		104
#define primitiveByteCodes		105
#define primitiveFlushCacheSelect	106
#define primitiveFlushCache		107
#define primitiveInputSemaphore		128
#define primitiveInputWord		129
#define primitiveBeDisplay		130
#define primitiveBeCursor		131
#define primitiveCopyBits		134
#define primitiveScanCharacter		135
#define primitiveDrawLoop		136
#define primitiveBitAt			138
#define primitiveBitAtPut		139
#define primitiveIdleWait		140
#define primitiveFileLoad		141
#define primitiveReplaceFromTo		142

int                 arrayAt(Objptr, int, Objptr *);
int                 arrayPutAt(Objptr, int, Objptr);
int                 primitive(int, Objptr, Objptr, int, int *);

extern Objptr	    compClass;
extern Objptr	    compCatagory;
