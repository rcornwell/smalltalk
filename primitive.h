
/*
 * Smalltalk interpreter: Primitive Methods.
 *
 * $Id: primitive.h,v 1.1 1999/09/02 15:57:59 rich Exp rich $
 *
 * $Log: primitive.h,v $
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
#define	primitiveFileGet		 86
#define	primitiveFilePut		 87
#define	primitiveFileSize		 88
#define	primitiveFileAtEnd		 89
#define	primitiveFileDir		 90
#define primitiveInternString		 91
#define primitiveClassComment		 92
#define primitiveMethodsFor		 93
#define primitiveError		 	 94
#define primitiveDumpObject		 95
#define primitiveTimeWordsInto		 96
#define primitiveTickWordsInto		 97
#define primitiveSignalAtTick		 98
#define primitiveStackTrace		 99
#define primitiveEvaluate		100
#define primitiveFillBuffer		101
#define primitiveFlushBuffer		102
#define primitiveByteAt			103
#define primitiveByteAtPut		104
 

int                 arrayAt(Objptr, int, Objptr *);
int                 arrayPutAt(Objptr, int, Objptr);
Objptr              MakeString(char *);
char               *Cstring(Objptr);
int                 doSnapShot(Objptr);
Objptr              internString(char *);
void                AddSelectorToIDictionary(Objptr, Objptr, Objptr);
Objptr              FindSelectorInIDictionary(Objptr, Objptr);
Objptr              FindKeyInIDictionary(Objptr, Objptr);
Objptr              new_IDictionary();
void                AddSelectorToDictionary(Objptr, Objptr);
Objptr              FindSelectorInDictionary(Objptr, Objptr);
Objptr              create_association(Objptr, Objptr);
Objptr              new_Dictionary();
void                AddSelectorToSet(Objptr, Objptr);
Objptr              FindSelectorInSet(Objptr, Objptr);
Objptr              new_Set();
int                 primitive(int, Objptr, Objptr, int, int *);

extern Objptr	    compClass;
extern Objptr	    compCatagory;
