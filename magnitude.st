" Methods for Class magnitude and all it's subclasses"

" $Id: magnitude.st,v 1.5 2001/08/18 16:17:01 rich Exp rich $ "

"
 $Log: magnitude.st,v $
 Revision 1.5  2001/08/18 16:17:01  rich
 Placed classes and methods in correct categories.
 Added LargeInteger, Fraction and Complex classes.
 Fixed Date and Time classes.

 Revision 1.4  2001/07/31 14:09:48  rich
 Code cleanup.
 Moved definition of Magnitude, Number, Integer class to init.c

 Revision 1.3  2001/01/08 05:53:21  rich
 Code cleanup

 Revision 1.2  2000/02/01 18:09:55  rich
 Added asString method to class Character.
 Fixed Character constants.
 Remove range checks from SmallInteger asCharacter since same
  checks are done in Character value:.

 Revision 1.1  1999/09/02 15:57:59  rich
 Initial revision

"
Object subclass: 'Magnitude'
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Comparision' !

Magnitude comment: 
 'I am a abstract class. I represent relationships between objects.' !

! Magnitude methodsFor: 'comparing'!

= aMagnitude
	self subclassResponsibility
!

< aMagnitude
	self subclassResponsibility
!

> aMagnitude
	self subclassResponsibility
!

<= aMagnitude
	^ (self < aMagnitude) | (self = aMagnitude)
!

>= aMagnitude
	^ (self > aMagnitude) | (self = aMagnitude)
!

between: min and: max
	^ (self >= min) and: [ self <= max ]
! !

! Magnitude methodsFor: 'testing'!

min: aMagnitude
	self < aMagnitude ifTrue: [ ^ self ]
			  ifFalse: [ ^ aMagnitude ].
!

max: aMagnitude
	self > aMagnitude ifTrue: [ ^ self ]
			  ifFalse: [ ^ aMagnitude ].
! !

"Magnitude subclass: 'Character'
	instanceVariableNames: 'value'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Comparision'" !

Magnitude addSubclass: Character !

Character category: 'Comparison' !

Character comment: 
 'I represent individual characters, my class is initialized by the system
and my values can''t be changed. ' !

! Character class methodsFor: 'built ins'!

value: anInteger
    "Returns the character object corresponding to anInteger.  Error if
     anInteger is not an integer, or not in 0..255."
    (anInteger between: 0 and: 255)
	ifFalse:
	    [ ^self error: 'invalid argument type or integer out of range']
	ifTrue:
	    [ ^ charsymbols basicAt: (anInteger + 1) ]
! !

! Character class methodsFor: 'constants'!

backspace
    ^charsymbols basicAt: 9
!

tab
    ^charsymbols basicAt: 10
!

nl
    ^charsymbols basicAt: 11
!

newPage
    ^charsymbols basicAt: 13
!

cr
    ^charsymbols basicAt: 16
!

esc
    ^charsymbols basicAt: 28
!

space
    ^charsymbols basicAt: 33
! !


! Character class methodsFor: 'instance creation'!

digitValue: anInteger
    "Returns a character that corresponds to anInteger.  0-9 map to $0-$9,
    10-35 map to $A-$Z"
    (anInteger between: 0 and: 9)
        ifTrue: [ ^Character value: anInteger + 48 ]. "48 == $0"
    (anInteger between: 10 and: 35)
        ifTrue: [ ^Character value: anInteger - 10 + 65 ]. "65 = $A"
    ^self error: 'value not in range 0 to 35'
! !

! Character methodsFor: 'converting'!

digitValue
    "Returns the value of self interpreted as a digit.  Here, 'digit' means
    either 0-9, or uppercase A-Z, which maps to 10-35."
    (self between: $0 and: $9) ifTrue: [ ^self asciiValue - 48 ].
                                "48 is $0"
    (self between: $A and: $Z) ifTrue: [ ^self asciiValue - 65 + 10 ].
                                "65 is $A"
    ^self error: 'Invalid digit character'
!

asString
    | s |
    s <- String new: 1.
    s at: 1 put: self.
    ^ s

! !

! Character methodsFor: 'comparing'!

= char
    "Boolean return value; true if the characters are equal Return true
     if they point to same object"
    <primitive 69>
!

asciiValue
    "Returns the integer value corresponding to self"
    ^ value
!

< aCharacter
    ^self asciiValue < aCharacter asciiValue
!

<= aCharacter
    ^self asciiValue <= aCharacter asciiValue
!

> aCharacter
    ^self asciiValue > aCharacter asciiValue
!

>= aCharacter
    ^self asciiValue >= aCharacter asciiValue
! !


! Character methodsFor: 'testing'!

isDigit
    "True if self is a 0-9 digit"
    ^self between: $0 and: $9
!

isLetter
    "True if self is an upper- or lowercase letter"
    ^(self between: $a and: $z) or: [ self between: $A and: $Z ]
!

isAlphaNumeric
    "True if self is a letter or a digit"
    ^self isLetter or: [ self isDigit ]
!

isLowercase
    "True if self is a lowercase letter"
    ^self between: $a and: $z
!

isUppercase
    "True if self is uppercase"
    ^self between: $A and: $Z
!

isSeparator
    "Returns true if self is a space, cr, tab, nl, or newPage"
    self > Character space ifTrue: [ ^false ].
    self = Character space ifTrue: [ ^true ].
    self = Character cr ifTrue: [ ^true ].
    self = Character tab ifTrue: [ ^true ].
    self = Character nl ifTrue: [ ^true ].
    self = Character newPage ifTrue: [ ^true ].
    ^false
!

isVowel
    "Returns true if self is a, e, i, o, or u; case insensitive"
    | char |
    char <- self asLowercase.
    char = $a ifTrue: [ ^true ].    
    char = $e ifTrue: [ ^true ].    
    char = $i ifTrue: [ ^true ].    
    char = $o ifTrue: [ ^true ].    
    char = $u ifTrue: [ ^true ].    
    ^false
! !

! Character methodsFor: 'conversion'!

asLowercase
    "Returns self as a lowercase character if it's an uppercase letter,
     otherwise returns the character unchanged."
    self isUppercase ifFalse: [ ^self ].
    ^Character value: (self asciiValue) + 32
!

asUppercase
    "Returns self as a uppercase character if it's an lowercase letter,
     otherwise returns the character unchanged."
    self isLowercase ifFalse: [ ^self ].
    ^Character value: (self asciiValue) - 32
!

asSymbol
    "Returns the character self as a symbol."
    | str |
    str <- String new: 1.
    str at: 1 put: self asciiValue.
    ^ str asSymbol
! !

! Character methodsFor: 'printing'!

printOn: aStream
    self storeOn: aStream
! !

! Character methodsFor: 'storing'!

storeOn: aStream
    aStream nextPut: $$.
    aStream nextPut: self
! !

Magnitude subclass: 'Number'
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Arithmetic' !
	
Number comment: 
 'I am a abstract class. I represent numeric objects.' !

! Number methodsFor: 'converting' !

degreesToRadians
	^ self / 57.29577951308
!

radiansToDegrees
	^ self * 57.29577951308
!

coerce: aNumber
	self subclassResponsibility
!

generality
	self subclassResponsibility
!

retry: aSymbol coercing: aNumber
	| selfGen aNumGen |
	selfGen <- self generality.
	aNumGen <- aNumber generality.
	selfGen > aNumGen
	    ifTrue: [ ^ self preform: aSymbol with: (self coerce: aNumber) ].
	selfGen < aNumGen
	    ifTrue: [ ^ (aNumber coerce: self) preform: aSymbol with: aNumber ].
	self error: 'retry:coercing: called with same generality'.
! !

! Number methodsFor: 'arithmetic'!

+ aNumber
    self subclassResponsibility
!

- aNumber
    self subclassResponsibility
!

* aNumber
    self subclassResponsibility
!

/ aNumber
    self subclassResponsibility
!

\\ aNumber
    self subclassResponsibility
!

// aNumber
    self subclassResponsibility
!

quo: aNumber
	"Return the integer quotient of dividing the reciever by aNumber"
	^ ( self / aNumber) truncated
!

rem: aNumber
	"Return the remainder of dividing the reciever by aNumber"
	^ self - ((self quo: aNumber) * aNumber)
!

reciprocal
        self = 0
                ifTrue: [self error: 'can not return the reciprocal of zero']
                ifFalse: [^1 / self]
! !

! Number methodsFor: 'truncation and round off'!

truncated
	^self subclassResponsibility
!

truncateTo: aNumber
	^(self / aNumber) truncated * aNumber
!

rounded
	"Returns the integer nearest the receiver"
	^(self + 0.5) truncated
!

roundTo: aNumber
	^(self / aNumber) rounded * aNumber
!

floor
        "Return the integer nearest the receiver toward negative infinity."
        | selfTruncated |
        selfTruncated <- self truncated.
        "If positive, truncation to zero is what we want."
        self >= 0 ifTrue: [^selfTruncated].
        "Must be negative."
        self = selfTruncated
                ifTrue: [^selfTruncated]
                ifFalse: [^selfTruncated - 1]
! !

! Number methodsFor: 'testing'!

negative
    ^self < 0
!

positive
    ^self >= 0
!

strictlyPositive
    ^self > 0
!

sign
    "Returns the sign of the receiver."
    self < 0 ifTrue: [ ^-1 ].
    self > 0 ifTrue: [ ^1 ].
    ^0
!

even
    "Returns true if self is divisible by 2"
    ^self truncated even
!

odd
    "Returns true if self is not divisible by 2"
    ^self truncated odd
! !

! Number methodsFor: 'misc math'!

squared
    ^self * self
!

abs
    self > 0 ifTrue: [ ^self ] ifFalse: [ ^self negated ]
!

negated
    ^0 - self
!

sin
    ^self asFloat sin
!

cos
    ^self asFloat cos
!

tan
    ^self asFloat tan
!

arcSin
    ^self asFloat arcSin
!

arcCos
    ^self asFloat arcCos
!

arcTan
    ^self asFloat arcTan
!

sqrt
    ^self asFloat sqrt
!

exp
    ^self asFloat exp
!

ln
    ^self asFloat ln
!

log: aNumber
    "return log base aNumber of the receiver"
    ^self ln / aNumber ln
!

floorLog: radix
    ^(self log: radix) floor
!

raisedToInteger: anInteger
    "Return self raised to anInteger power"
    | result |
    result <- self coerce: 1.
    anInteger timesRepeat: [ result <- result * self ].
    ^result
! !

! Number methodsFor: 'iteration' !

to: stop by: step do: aBlock
    | i |
    i <- self.
    step > 0
        ifTrue: [
            [ i <= stop ]
                whileTrue: [ aBlock value: i.
                             i <- i + step ]
        ]
        ifFalse: [
            [ i >= stop ]
                whileTrue: [ aBlock value: i.
                             i <- i + step ]
        ].
    ^ i
!

to: stop do: aBlock
    ^self to: stop by: 1 do: aBlock
! !

Number subclass: 'Fraction'
	instanceVariableNames: 'numerator denominator'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Arithmetic'!

Fraction comment:
' I represent rational numbers in the form (p/q) where p and q are integers.
The arithmetic operations  *, +, -, /,  on fractions, all return a reduced 
fraction.' !

! Fraction class methodsFor: 'instance creation' !

numerator: nInteger denominator: dInteger 
	" Answer a new instance of fraction (nInteger/dInteger)"

	^self new setNumerator: nInteger setDenominator: dInteger 
! !

! Fraction methodsFor: 'accessing' !

denominator
	^denominator
!

numerator
	^numerator 
! !

! Fraction methodsFor: 'arithmetic' !

* aNumber 
	"I implement * for fractions."

	(aNumber isMemberOf: Fraction)
	    ifTrue: [^(Fraction numerator: numerator * aNumber numerator
			        denominator: denominator * aNumber denominator)
				    reduced]
	    ifFalse: [^self retry: #* coercing: aNumber]
!

+ aNumber 
	"I implement + for fractions."

	(aNumber isMemberOf: Fraction)
	    ifTrue: [^(Fraction numerator: (numerator * aNumber denominator)
		     			+ (aNumber numerator * denominator)
			        denominator: denominator * aNumber denominator)
				     reduced]
	    ifFalse: [^self retry: #+ coercing: aNumber]
!

- aNumber 
	"I implement - for fractions."

	(aNumber isMemberOf: Fraction)
		ifTrue: [^self + (aNumber negated)]
		ifFalse: [^self retry: #- coercing: aNumber]
!

/ aNumber 
	"I implement / for fractions."

	(aNumber isMemberOf: Fraction)
		ifTrue: [^self * (aNumber reciprocal)]
		ifFalse: [^self retry: #/ coercing: aNumber] 
!

// aNumber
    "Return the integer quotient of dividing the receiver by aNumber with
    truncation towards negative infinity."
    ^(self / aNumber) floor 
!

\\ aNumber
    "Return the remainder from dividing the receiver by aNumber, (using //)."
    ^(self - (self // aNumber * aNumber)) 
!

negated
	^Fraction numerator: numerator negated denominator: denominator 
!

reciprocal
	denominator < 0
	    ifTrue: [^Fraction numerator: denominator negated 
			       denominator: numerator negated]
	    ifFalse: [^Fraction numerator: denominator 
			       denominator: numerator]

! !

! Fraction methodsFor: 'coercing' !

coerce: aNumber 
	^aNumber asFraction
!

generality
	^3
!

truncated
	^numerator quo: denominator
! !

! Fraction methodsFor: 'comparing' !

< arg 
	"I test if the receiver is less than arg."

	(arg isMemberOf: Fraction)
		ifTrue: [^arg denominator * numerator < 
				 (denominator * arg numerator)]
		ifFalse: [^self retry: #< coercing: arg]
!

> arg 
	"I test if the receiver is more than arg."

	(arg isMemberOf: Fraction)
		ifTrue: [^arg denominator * numerator >
				 (denominator * arg numerator)]
		ifFalse: [^self retry: #> coercing: arg]
!

= arg 
	"I test if the receiver is equals arg."

	(arg isMemberOf: Fraction)
		ifTrue: [^arg denominator * numerator = 
				(denominator * arg numerator)]
		ifFalse: [^self retry: #= coercing: arg]
!

hash
	^numerator bitXor: denominator
! !

! Fraction methodsFor: 'converting' !

asInteger
	^ self truncated
!

asFloat
	^numerator asFloat / denominator asFloat
!

asFraction
	^self 
! !

! Fraction methodsFor: 'printing' !

printOn: aStream

	" Fractions print as (numerator/denominator) eg (3/4) ."

	aStream nextPut: $( .
	aStream print: numerator.
	aStream nextPut: $/ .
	aStream print: denominator.
	aStream nextPut: $) 
! !

! Fraction methodsFor: 'private' !

reduced
	| gcd |
	numerator = 1 ifTrue: [^self].
	denominator = 1 ifTrue: [^numerator].
	numerator = 0 ifTrue: [^0].
	numerator = denominator ifTrue: [^1].
	gcd <- numerator gcd: denominator.
	gcd = 1 ifTrue: [^self].
	denominator = gcd ifTrue: [^numerator // gcd].
	^Fraction numerator: numerator // gcd 
		  denominator: denominator // gcd 
!

setNumerator: numInteger setDenominator: denInteger 
	denInteger = 0
		ifTrue: [^self error: 'The denominator can not be zero'].
	denInteger < 0
		ifTrue: [numerator <- numInteger negated.
			denominator <- denInteger negated]
		ifFalse: [numerator <- numInteger.
			denominator <- denInteger]
! !

Number subclass: 'Integer'
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Arithmetic' !

Integer comment: ' I represent integer numbers.' !

! Integer methodsFor: 'misc math' !

factorial
    self < 2 ifTrue: [ ^1 ]
             ifFalse: [ ^self * (self - 1) factorial ]
!

gcd: anInteger
    | selfInteger temp temp1 |
    "Return the greatest common divisor (Euclid's algorithm)"
    selfInteger <- self.
    temp1 <- anInteger.
    [ temp1 ~= 0 ]
        whileTrue: [ temp <- selfInteger \\ temp1.
                     selfInteger <- temp1.
                     temp1 <- temp. ].
    ^selfInteger
!

lcm: anInteger
    ^(self * anInteger) abs // (self gcd: anInteger)
!

even
    ^(self bitAnd: 1) = 0
!

odd
    ^(self bitAnd: 1) ~= 0

! !

! Integer methodsFor: 'bit manipulation'!

bitAt: index
        ^(self bitShift: (index negated)) bitAnd: 1
!

bitAt: index put: aBoolean
	| bit |
	bit <- 1 bitShift: index.
	self bitOr: bit.
	aBoolean ifFalse: [ self bitXor: bit ].
!

bitInvert
	" Return one's compliment of reciever"
	^ self negated - 1
!

allMask: anInteger
	"True if all bits in anInteger are 1 in receiver"
	^ (self bitAnd: anInteger) = anInteger
!

anyMask: anInteger
	"True if any bits in anInterger are 1 in receiver"
	^ (self bitAnd: anInteger) ~= 0
!

noMask: anInteger
	"True if no bits in anInteger are 1 in reciever"
	^ (self bitAnd: anInteger) = 0
! !

! Integer methodsFor: 'iteration' !

timesRepeat: aBlock
	| i |
	i <- 1.
	[ i <= self ] whileTrue: [ aBlock value. i <- i + 1]
! !

! Integer methodsFor: 'conversion'!

asInteger
    ^ self
!

asCharacter
    "Return self as an ascii character"
    ^Character value: self
!

asFraction
    ^Fraction numerator: self denominator: 1
!

asFloat
    <primitive 18>
!

asLargeInteger
    <primitive 127>
! !

! Integer methodsFor: 'truncation and round off'!

ceiling
    ^self
!

floor
    ^self
!

truncated
    ^self
!

rounded
    ^self
! !

! Integer methodsFor: 'coercing' !

coerce: aNumber
    ^aNumber truncated
! !

! Integer methodsFor: 'copying'!

shallowCopy
    ^self
!

deepCopy
    ^self
! !

! Integer methodsFor: 'printing'!

printOn: aStream base: b
    aStream nextPutAll: (self radix: b)
!

radix: baseInteger
    ^self signedStringBase: baseInteger showRadix: true
!

printOn: aStream
    aStream nextPutAll: (self signedStringBase: 10 showRadix: false)
! !

! Integer methodsFor: 'storing'!

storeOn: aStream
    self printOn: aStream 
! !

! Integer methodsFor: 'private'!

unsignedStringBase: radix string: aStream
    self ~= 0 ifTrue: [
	(self // radix ) unsignedStringBase: radix string: aStream.
	aStream nextPut: (Character digitValue: (self \\ radix))
    ]
!
    
signedStringBase: radix showRadix: showRadix
    | str num |
    str <- WriteStream on: (String new: 1).
    self negative
        ifTrue: [ str nextPut: $-.
                  num <- self negated ]
        ifFalse: [ num <- self ].
    num = 0 ifTrue: [ str nextPut: $0 ]
    	    ifFalse: [num unsignedStringBase: radix string: str].
    showRadix ifTrue:
          [ str nextPut: $r.
	    radix unsignedStringBase: 10 string: str ].
    ^str contents
! !

Integer wordSubclass: 'SmallInteger'
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Arithmetic' !

"SmallInteger category: 'Arithmetic' " !

"Integer addSubclass: SmallInteger " !

SmallInteger comment: 
	'I represent integer numbers that are built into the system. ' !

! SmallInteger methodsFor: 'arithmetic' !

+ aNumber
    <primitive 1>
    ^ self retry: #+ coercing: aNumber
!

- aNumber
    <primitive 2>
    ^ self retry: #- coercing: aNumber
!

* aNumber
    <primitive 3>
    ^ self retry: #* coercing: aNumber
!

/ aNumber
    <primitive 4>
    ^(Fraction numerator: self denominator: aNumber)
!

\\ aNumber
    <primitive 5>
    ^ self retry: #\\ coercing: aNumber
!

// aNumber
    <primitive 6>
    ^ self retry: #// coercing: aNumber
! !


! SmallInteger methodsFor: 'comparison' !

= aNumber
    <primitive 11>
    ^ self retry: #= coercing: aNumber
!

~= aNumber
    <primitive 12>
    ^ self retry: #~= coercing: aNumber
!

< aNumber
    <primitive 13>
    ^ self retry: #< coercing: aNumber
!

> aNumber
    <primitive 14>
    ^ self retry: #> coercing: aNumber
!

<= aNumber
    <primitive 15>
    ^ self retry: #<= coercing: aNumber
!

>= aNumber
    <primitive 16>
    ^ self retry: #>= coercing: aNumber
!

negative
    ^ self < 0
!

positive
    ^ self >= 0
! !

! SmallInteger methodsFor: 'bit manipulation'!

bitAnd: aNumber
    <primitive 7>
    ^ self retry: #bitAnd: coercing: aNumber
!

bitOr: aNumber
    <primitive 8>
    ^ self retry: #bitOr: coercing: aNumber
!

bitXor: aNumber
    <primitive 9>
    ^ self retry: #bitXor: coercing: aNumber
!

bitShift: aNumber
    <primitive 10>
    ^ self retry: #bitShift: coercing: aNumber
!

highBit
	"Return first one bit in reciever"
	self = 0 ifTrue: [ ^ -1 ].
	30 to: 0 step: -1 do:
	   [ :i | (self bitAnd: (1 bitShift: i)) ~= 0 ifTrue: [ ^i ] ]
! !

! SmallInteger methodsFor: 'misc methods' !

asObject
        "Answer an integer pointer for object."
        <primitive 61>
        ^ self primitiveFailed
!

hash
	^ self
! !

! SmallInteger methodsFor: 'coercing' !

generality
	^ 1
! !

Integer variableByteSubclass: 'LargePositiveInteger'
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Arithmetic' !

LargePositiveInteger comment: 
   'I represent positive integer numbers that are too big for SmallInteger. ' !


! LargePositiveInteger methodsFor: 'arithmetic' !

+ aNumber
    <primitive 111>
    ^ self retry: #+ coercing: aNumber
!

- aNumber
    <primitive 112>
    ^ self retry: #- coercing: aNumber
!

* aNumber
    <primitive 113>
    ^ self retry: #* coercing: aNumber
!

/ aNumber
    <primitive 114>
    ^(Fraction numerator: self denominator: aNumber)
!

\\ aNumber
    <primitive 115>
    ^ self retry: #\\ coercing: aNumber
!

// aNumber
    <primitive 116>
    ^ self retry: #// coercing: aNumber
! !


! LargePositiveInteger methodsFor: 'comparison' !

= aNumber
    <primitive 121>
    ^ self retry: #= coercing: aNumber
!

~= aNumber
    <primitive 122>
    ^ self retry: #~= coercing: aNumber
!

< aNumber
    <primitive 123>
    ^ self retry: #< coercing: aNumber
!

> aNumber
    <primitive 124>
    ^ self retry: #> coercing: aNumber
!

<= aNumber
    <primitive 125>
    ^ self retry: #<= coercing: aNumber
!

>= aNumber
    <primitive 126>
    ^ self retry: #>= coercing: aNumber
!

negative
    ^ false
!

positive
    ^ true
!

strictlyPositive
    ^self > 0
!

sign
    "Returns the sign of the receiver."
    self ~= 0 ifTrue: [ ^1 ].
    ^0
! !

! LargePositiveInteger methodsFor: 'bit manipulation'!

bitAnd: aNumber
    <primitive 117>
    self primitiveFail
!

bitOr: aNumber
    <primitive 118>
    self primitiveFail
!

bitXor: aNumber
    <primitive 119>
    self primitiveFail
!

bitShift: aNumber
    <primitive 120>
    self primitiveFail
!

highBit
	| size |
	"Return first one bit in reciever"
	self = 0 ifTrue: [ ^ -1 ].
	size <- self basicSize * 32.
	size to: 0 step: -1 do:
	   [ :i | (self bitAnd: (1 bitShift: i)) ~= 0 ifTrue: [ ^i ] ]
! !

! LargePositiveInteger methodsFor: 'misc math'!

abs
    ^ self 
!

hash
	^ self
!

negated
    <primitive 137>
    ^ 0 - self
! !

! LargePositiveInteger methodsFor: 'coercing' !

coerce: aNumber
	^ aNumber asLargeInteger
!

generality
	^ 2
! !

Integer variableByteSubclass: 'LargeNegativeInteger'
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Arithmetic' !

LargeNegativeInteger comment: 
   'I represent negative integer numbers that are too big for SmallInteger. ' !


! LargeNegativeInteger methodsFor: 'arithmetic' !

+ aNumber
    <primitive 111>
    ^ self retry: #+ coercing: aNumber
!

- aNumber
    <primitive 112>
    ^ self retry: #- coercing: aNumber
!

* aNumber
    <primitive 113>
    ^ self retry: #* coercing: aNumber
!

/ aNumber
    <primitive 114>
    ^(Fraction numerator: self denominator: aNumber)
!

\\ aNumber
    <primitive 115>
    ^ self retry: #\\ coercing: aNumber
!

// aNumber
    <primitive 116>
    ^ self retry: #// coercing: aNumber
! !

! LargeNegativeInteger methodsFor: 'comparison' !

= aNumber
    <primitive 121>
    ^ self retry: #= coercing: aNumber
!

~= aNumber
    <primitive 122>
    ^ self retry: #~= coercing: aNumber
!

< aNumber
    <primitive 123>
    ^ self retry: #< coercing: aNumber
!

> aNumber
    <primitive 124>
    ^ self retry: #> coercing: aNumber
!

<= aNumber
    <primitive 125>
    ^ self retry: #<= coercing: aNumber
!

>= aNumber
    <primitive 126>
    ^ self retry: #>= coercing: aNumber
!

negative
    ^ true
!

positive
    ^ false
!

strictlyPositive
    ^ false
!

sign
    "Returns the sign of the receiver."
    ^ -1
! !

! LargeNegativeInteger methodsFor: 'bit manipulation'!

bitAnd: aNumber
    <primitive 117>
    self primitiveFail
!

bitOr: aNumber
    <primitive 118>
    self primitiveFail
!

bitXor: aNumber
    <primitive 119>
    self primitiveFail
!

bitShift: aNumber
    <primitive 120>
    self primitiveFail
!

highBit
	| size |
	"Return first one bit in reciever"
	^ self basicSize * 32.
! !

! LargeNegativeInteger methodsFor: 'misc math'!

abs
    ^ self negated
!

hash
	^ self
!

negated
    <primitive 137>
    ^ 0 - self
! !

! LargeNegativeInteger methodsFor: 'coercing' !

coerce: aNumber
	^ aNumber asLargeInteger
!

generality
	^ 2
! !

Number variableByteSubclass: 'Float'
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Arithmetic' !

Float comment: 
   'I represent real number. ' !

! Float methodsFor: 'arithmetic' !

+ aNumber
    <primitive 19>
    ^ self retry: #+ coercing: aNumber
!

- aNumber
    <primitive 20>
    ^ self retry: #- coercing: aNumber
!

* aNumber
    <primitive 21>
    ^ self retry: #* coercing: aNumber
!

/ aNumber
    <primitive 22>
    ^ self retry: #/ coercing: aNumber
!

// aNumber
    ^ ( self / aNumber ) floor
!

\\ aNumber
    ^ ( self - ( self // aNumber * aNumber)) floor
!

integerPart
	^ self - self fractionPart
! !

! Float methodsFor: 'comparison' !

= aNumber
    <primitive 23>
    ^ self retry: #= coercing: aNumber
!

~= aNumber
    <primitive 24>
    ^ self retry: #~= coercing: aNumber
!

< aNumber
    <primitive 25>
    ^ self retry: #< coercing: aNumber
!

> aNumber
    <primitive 26>
    ^ self retry: #> coercing: aNumber
!

<= aNumber
    <primitive 27>
    ^ self retry: #<= coercing: aNumber
!

>= aNumber
    <primitive 28>
    ^ self retry: #>= coercing: aNumber

!

negative
    ^ self < 0
!

positive
    ^ self >= 0
! !

! Float methodsFor: 'truncation and round off'!

truncated
	<primitive 29>
!

fractionPart
	<primitive 30>
!

exponent
	<primitive 31>
! !

! Float methodsFor: 'misc math'!

exp
	<primitive 33>
!

ln
	<primitive 34>
!

timesTwoPower: aNumber
	<primitive 32>
!

raisedTo: aNumber
	<primitive 35>
	^ self retry: #raisedTo: coercing: aNumber
!

sqrt
	<primitive 36>
!

ceiling
	<primitive 37>
!

floor
	<primitive 38>
!

sin
	<primitive 39>
!

cos
	<primitive 40>
!

tan
	<primitive 41>
!

arcSin
	<primitive 42>
!

arcCos
	<primitive 43>
!

arcTan
	<primitive 44>
!

hash
	| expt |
	expt <- self exponent.
	expt >= 0 & (expt < 31)
		ifTrue: [ ^ self truncated ]
		ifFalse: [ ^ expt ]
! !

! Float class methodsFor: 'constants' !

pi
	"Returns the value of pi"
	^ 3.1415926535897
! !

! Float methodsFor: 'coercing' !

coerce: aNumber
	^ aNumber asFloat
!

generality
	^4
! !

! Float methodsFor: 'conversion' !

asInteger
	^ self truncated
!

asFloat
	^ self
! !

! Float methodsFor: 'copying' !

shallowCopy
	^ self
!

deepCopy
	^ self
! !

! Float methodsFor: 'printing'!

printOn: aStream
    | num exp |
    (self exponent between: -50 and: 49)
        ifTrue: [ self printFloatOn: aStream ]
        ifFalse: [ exp <- 0.
                   num <- self.
                   num abs < 1.0
                      ifTrue: [ [ num abs < 1.0 ] whileTrue:
                                    [ num <- num * 10.0 .
                                      exp <- exp - 1 ] ]
                      ifFalse: [ [num abs >= 10.0] whileTrue:
                                    [ num <- num / 10.0 .
                                      exp <- exp + 1 ] ].
                   num printFloatOn: aStream.
                   aStream nextPut: $e.
                   exp printOn: aStream ].
! !

! Float methodsFor: 'storing'!

storeOn: aStream
    self printOn: aStream
! !


! Float methodsFor: 'private'!

printFloatOn: aStream
    | num str intDigits |
    num <- self.
    num < (0.0 asFloat) ifTrue:
        [ aStream nextPut: $-.
          num <- num negated. ].
    intDigits <- num printIntegerPartOn: aStream.
    aStream nextPut: $..
    num printFracPartOn: aStream digitsPrinted: intDigits.
!

printIntegerPartOn: aStream
    | num digitString numDigits |
    num <- self integerPart.
    (digitString <- num revDigitsBase: 10.0) reverseDo:
        [ :char | aStream nextPut: char ].
    numDigits <- digitString size.
    $0 = (digitString at: 1)    "we've been forced to emit a 0; doesn't count"
        ifTrue: [ numDigits <- numDigits - 1 ].
    ^numDigits
!

printFracPartOn: aStream digitsPrinted: numDigits
    | num count zeroCount digit digitLimit |
    num <- self fractionPart.
    num = 0.0 ifTrue: [ ^aStream nextPut: $0 ].
    zeroCount <- count <- 0 .

    " produce the digits, up to a maximum of 15, suppressing trailing
      zeros (ln(2^52)/ln(10)) "
    digitLimit <- 15 - numDigits.
    [ (num ~= 0.0) & (count < digitLimit) ] whileTrue:
        [ num <- num * 10.0 .
          digit <- num floor.
          digit = 0             "for trailing zero suppression"
            ifTrue: [ zeroCount <- zeroCount + 1 ]
            ifFalse: [ aStream next: zeroCount put: $0.
                       aStream nextPut: (Character digitValue: digit).
                       zeroCount <- 0 ].
          num <- num fractionPart.
          count <- count + 1 ].
    zeroCount = digitLimit ifTrue: [ aStream nextPut: $0 ]
!

revDigitsBase: b    
    | str num digit |
    str <- WriteStream on: (String new: 10).
    self = 0.0
        ifTrue: [ str nextPut: $0 ]
        ifFalse: [
            num <- self.
            [ num = 0.0 ] whileFalse:
                [ "stdout nextPutAll: '------------'; nl.
                  num basicPrint.
                  (num/b) basicPrint.
                  (num/b) fractionPart basicPrint.
                  ((num/b) fractionPart * b) basicPrint.
                  ((num/b) fractionPart * b) rounded basicPrint."
                  digit <- ((num / b) fractionPart * b) rounded.
                  str nextPut: (Character digitValue: digit).
                  num <- (num / b) integerPart ] ].
    ^str contents
! !

Number subclass: 'Complex'
	instanceVariableNames: 'real imaginary '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Arithmetic' !

Complex comment: 
' I represent complex numbers in the form (a + ib) where a and b are real
 numbers.' !

! Complex class methodsFor: 'instance creation' !

real: a imaginary: b
	^ self new real: a imaginary: b.
! !

! Complex methodsFor: 'modifying' !

imaginary: aNumber
	imaginary <- aNumber.
!

real: aNumber
	real <- aNumber.
!

real: aNumber imaginary: anotherNumber
	real <- aNumber.
	imaginary <- anotherNumber.
! !

! Complex methodsFor: 'misc math' !

exp
	"Raises e to the power of the receiver."
	| a b |
	a <- self real.
	b <- self imaginary.
	^ Complex real: (a exp) * (b cos) imaginary: (a exp) * (b sin).
!

raisedTo: n
	"Answer the receiver raised to the power of n."

	| r theta |
	r <- self abs.
	theta <- self arg.

	^ Complex real: ((r raisedTo: n) * theta cos)
		  imaginary: ((r raisedTo: n) * theta sin).
! !

! Complex methodsFor: 'arithmetic' !

* z
	"Multiply two complex numbers."

	| a b c d |
	a <- self real.
	b <- self imaginary.
	c <- z real.
	d <- z imaginary.
	^ Complex real: ((a * c) - (b * d))
		  imaginary: ((a * d) + (b * c)).
!

+ z
	"Add two complex numbers."

	^ Complex real: (self real + z real) 
		  imaginary: (self imaginary + z imaginary).
!

- z
	"Subtract the argument fromthe receiver."

	^ Complex real: (self real - z real)
		  imaginary: (self imaginary - z imaginary).
!

/ z
	"Divide two complex numbers."

	| a b c d e f |
	(z abs = 0.0)
		ifTrue: [ self error: 'division by zero']
		ifFalse: [
			a <- self real.
			b <- self imaginary.
			c <- z real.
			d <- z imaginary.
		
			e <- ((a * c) + (b * d)) / ((c * c) + (d * d)).
			f <- ((b * c) - (a * d)) / ((c * c) + (d * d)).
			^ Complex real: e imaginary: f].
!

abs
	"Return the absolute value of the receiver."

	| a b | 
	a <- self real.
	b <- self imaginary.
	^ ((a * a) + (b * b)) sqrt. 
!

arg
	"Return the argument (angle in radians) of a complex number."

	| a b |
	a <- self real.
	b <- self imaginary.

	(a > 0.0)
		ifTrue: [ ^ (b / a) arcTan ].
	(a = 0.0)
		ifTrue: [ (b = 0.0) 
				ifTrue: [ ^ 0.0 ]
				ifFalse: [ ^ (b / b abs) arcSin ]].
	(a < 0.0)
		ifTrue: [ (b >= 0.0)
				ifTrue: [ ^ (b / a) arcTan + (-1 arcCos) ]
				ifFalse: [ ^ (b / a) arcTan - (-1 arcCos) ]].
!

conjugate
	"Return the complex conjugate of the receiver."

	^ Complex real: (self real) imaginary: (self imaginary negated).
!

negated
	"Return the complex number which is the additive inverse of the
		 receiver."

	^ Complex real: (self real negated) imaginary: (self imaginary negated).! !

! Complex methodsFor: 'printing' !

print
	^ Array with: (self real) with: (self imaginary).
! !

! Complex methodsFor: 'accessing' !

imaginary

	^ imaginary.
!

real

	^ real.
! !


Magnitude subclass: 'Time'
	  instanceVariableNames: 'seconds'
	  classVariableNames: ''
	  poolDictionaries: ''
	  category: 'Date-Time' !

Time comment: 
'My instances represent times of the day.  I provide methods for instance 
creation, methods that access components (hours, minutes, and seconds) of a 
time value, and a block execution timing facility.' !

! Time class methodsFor: 'creation'!

now
    ^self new setSeconds: Time secondClock
!

secondClock
    <primitive 96>
!

millisecondClock
    <primitive 97>
!

fromSeconds: secondCount
    ^self new setSeconds: (Time secondClock \\ (24*60*60)) + secondCount
!

millisecondClockValue
    ^self millisecondClock
!

millisecondsToRun: timedBlock
    | startTime|
    startTime <- self millisecondClock.
    timedBlock value.
    ^self millisecondClock - startTime
! !

! Time methodsFor: 'accessing'!

hours
    ^(seconds // (60*60)) \\ 24
!

minutes
    ^(seconds // 60) \\ 60
!

seconds
    ^seconds \\ 60
! !


! Time methodsFor: 'comparing'!

= aTime
    ^seconds = aTime time
!

< aTime
    ^seconds < aTime time
!

> aTime
    ^seconds > aTime time
!
	
<= aTime
    ^seconds <= aTime time
!

>= aTime
    ^seconds >= aTime time
!

hash
    ^seconds
! !

! Time methodsFor: 'arithmetic'!

addTime: timeAmount
    ^Time new setSeconds: seconds + timeAmount
!

subtractTime: timeAmount
    ^Time new setSeconds: seconds - timeAmount
! !

! Time methodsFor: 'printing' !

printOn: aStream
    self hours printOn: aStream.
    aStream nextPut: $:.
    self minutes < 10 ifTrue: [ aStream nextPut: $0 ].
    self minutes printOn: aStream.
    aStream nextPut: $:.
    self seconds < 10 ifTrue: [ aStream nextPut: $0 ].
    self seconds printOn: aStream
! !

! Time methodsFor: 'private'!

setSeconds: secs
    seconds <- secs
!

time
    ^seconds
! !

Magnitude subclass: 'Date'
	  instanceVariableNames: 'days'
          classVariableNames: 'DayNameDict MonthNameDict'
 	  poolDictionaries: ''
	  category: 'Date-Time' !

Date comment: 
'My instances represent dates.  My base date is defined to be Jan 1, 1901.
I provide methods for instance creation (including via "symbolic" dates, 
such as "Date newDay: 14 month: #Feb year: 1990"' !

! Date class methodsFor: 'initializing'!

initialize
    self initDayNameDict.
    self initMonthNameDict
!

initDayNameDict
    | dayNames |
    DayNameDict <- Dictionary new.
    dayNames <- #(
                 (monday mon)   "1"
                 (tuesday tue)  "2"
                 (wednesday wed) "3"
                 (thursday thu) "4"
                 (friday fri)   "5"
                 (saturday sat) "6"
                 (sunday sun)   "7"
                ).
    1 to: dayNames size do:
        [ :index | (dayNames at: index) do:
            [ :n | DayNameDict at: n put: index ] ].
!

initMonthNameDict
    | monthNames |
    MonthNameDict <- Dictionary new.
    monthNames <- #(
                 (january   jan)        "1"
                 (february  feb)        "2"
                 (march     mar)        "3"
                 (april     apr)        "4"
                 (may	    may)        "5"
                 (june      jun)        "6"
                 (july      jul)        "7"
                 (august    aug)        "8"
                 (september sep)        "9"
                 (october   oct)        "10"
                 (november  nov)        "11"
                 (december  dec)        "12"
                ).
    1 to: monthNames size do:
        [ :index | (monthNames at: index) do:
            [ :n | MonthNameDict at: n put: index ] ].
! !

! Date class methodsFor: 'basic'!

dayOfWeek: dayName
    ^DayNameDict at: dayName asLowercase asSymbol
!

nameOfDay: dayIndex
    ^#(Monday Tuesday Wednesday Thursday Friday Saturday Sunday) at: dayIndex
!

indexOfMonth: monthName
    ^MonthNameDict at: monthName asLowercase asSymbol
!

nameOfMonth: monthIndex
    ^#(January February  March
       April   May       June
       July    August    September
       October November  December) at: monthIndex
!

daysInMonth: monthName forYear: yearInteger
    | monthIndex |
    monthIndex <- self indexOfMonth: monthName.
    ^self daysInMonthIndex: monthIndex forYear: yearInteger
!

daysInYear: yearInteger
    ^365 + (self leapYear: yearInteger)
!

leapYear: yearInteger
    (yearInteger \\ 4 = 0
        and: [ yearInteger \\ 100 ~= 0
            or: [ yearInteger \\ 400 = 0 ] ]) 
        ifTrue: [ ^1 ]
        ifFalse: [ ^0 ]
!

dateAndTimeNow
    ^Array with: (Date today) with: (Time now)
! !

! Date class methodsFor: 'creation'!

today
    | now date |
    now <- Time secondClock.
    date <- now // (24 * 60 * 60).
    ^self new setDays: date + 25201 "(69 * 365 + 16)"
!

fromDays: dayCount
    ^self new setDays: dayCount
!

newDay: dayCount year: yearInteger
    ^self new setDays: (dayCount + self yearAsDays: yearInteger)
!

newDay: day month: monthName year: yearInteger
    ^self new setDays:
        (day + (self daysUntilMonth: monthName year: yearInteger)
             + (self yearAsDays: yearInteger))
! !

! Date class methodsFor: 'private methods'!

yearAsDays: yearInteger
   | temp |
    "Returns the number of days since Jan 1, 1901."
    temp <- yearInteger - 1900.
    ^(temp - 1) * 365
        + (temp // 4)
        - (temp // 100)
        + (temp // 400)
!

daysUntilMonth: monthName year: yearInteger
    | monthIndex totalDays |
    totalDays <- 0.
    monthIndex <- self indexOfMonth: monthName.
    1 to: monthIndex - 1 do:
        [ :index | totalDays <- totalDays + (self daysInMonthIndex: index
                                                 forYear: yearInteger) ].
    ^totalDays
!


daysInMonthIndex: monthIndex forYear: yearInteger
    | days |
    days <- #(31 28 31           "Jan Feb Mar"
            30 31 30            "Apr May Jun"
            31 31 30            "Jul Aug Sep"
            31 30 31            "Oct Nov Dec"
            ) at: monthIndex.
    monthIndex = 2
        ifTrue: [ ^days + (self leapYear: yearInteger) ]
        ifFalse: [ ^days ]

! !

! Date methodsFor: 'arithmetic'!

addDays: dayCount
    days <- days + dayCount
!

subtractDays: dayCount
    days <- days - dayCount
!

subtractDate: aDate
    ^days - aDate days
! !

! Date methodsFor: 'comparing'!

= aDate
    ^days = aDate days
!

< aDate
    ^days < aDate days
!

> aDate
    ^days > aDate days
!

<= aDate
    ^days <= aDate days
!

>= aDate
    ^days >= aDate days
!

hash
    ^days
! !

! Date methodsFor: 'printing'!

printOn: aStream
    self computeDateParts:
        [ :year :month :day |
            day printOn: aStream.
            aStream nextPut: $- .
            aStream nextPutAll: (((Date nameOfMonth: month) asString) 
				copyFrom: 1 to: 3).
            aStream nextPut: $- .
            year printOn: aStream ]
! !


! Date methodsFor: 'storing'!

storeOn: aStream
    "Won't work past around 1200 years in the future"
    aStream nextPut: $(.
    aStream nextPutAll: self classNameString.
    self computeDateParts:
        [ :year :month :day |
            aStream nextPutAll: ' newDay: '.
            aStream store: day.
            aStream nextPutAll: ' month: '.
            aStream store: (Date nameOfMonth: month).
            aStream nextPutAll: ' year: '.
            aStream store: year ].
    aStream nextPut: $)
! !

! Date methodsFor: 'private methods'!

days
    ^days
!

setDays: dayCount
    days <- dayCount
!

computeDateParts: aBlock
    | yearInteger tempDays monthIndex daysInMonth |
    tempDays <- days - (days // 1460) "4*365"
                    + (days // 36500) "100*365"
                    - (days // 146000). "400*365"
    yearInteger <- tempDays // 365.
    "The +1 below makes tempDays be 1 based, instead of 0 based, so that the
     first day is 1 Jan 1901 instead of 0 jan 1901"
    tempDays <-days - (yearInteger * 365)
                    - (yearInteger // 4)
                    + (yearInteger // 100)
                    - (yearInteger // 400)
                    + 1.
    yearInteger <- yearInteger + 1901.
    monthIndex <- 1.
    [ monthIndex < 12
        and: [ daysInMonth <- Date daysInMonthIndex: monthIndex
                                  forYear: yearInteger.
               tempDays > daysInMonth ] ] whileTrue:
        [ monthIndex <- monthIndex + 1.
          tempDays <- tempDays - daysInMonth ].
    ^aBlock value: yearInteger value: monthIndex value: tempDays
! !

Date initialize !

