" Bootstrap methods to define classes"

" $Id: basic.st,v 1.3 2000/08/27 12:24:04 rich Exp rich $ "
        
"
 $Log: basic.st,v $
 Revision 1.3  2000/08/27 12:24:04  rich
 Make sure objects respond to basicNew.
 New Method to return number of bytecodes in a method.
 Misc code cleanup.

 Revision 1.2  2000/02/01 18:09:44  rich
 Added Stack checking.
 Added CompiledMethod class.
 Instance variables now stored in a Array.
 Support for class variables.
 Fixed bug in instance flags reading methods.
 Fixed bug in dictionary, set access.
 Fixes to File class.

 Revision 1.1  1999/09/02 15:57:59  rich
 Initial revision

"
Object comment:
	'I am the root class of all Smalltalk classes.' !

! Object methodsFor: 'Private'!

DumpObject
	<primitive 95>
! !

! Object methodsFor: 'Testing'!

isNil
	^false
!

notNil
	^true
! !

! Object methodsFor: 'Comparing'!

== anObject
	"Returns true if the objects are the same."
	<primitive 69>
	^ self primitiveFailed
!

= anObject
	"Returns true if object represent same value."
	^ self == anObject
!

~= anObject
	"Returns true if the objects are not the same."
	^ (self == anObject) not
!

~~ anObject
	"Returns true if the objects don't represent the same thing."
	^ (self = anObject) not
! !

! Object methodsFor: 'Testing Functionality'!

class
	"Returns class of object"
	<primitive 70>
	^ self primitiveFailed
!


isMemberOf: aClass
	"Returns true if object is a member of aClass"
	^ self class == aClass
!

isKindOf: aClass
	"Tests if object is a class of aClass"
	^ (self isMemberOf: aClass) or:
		[ self class inheritsFrom: aClass ] 

! !

! Object methodsFor: 'Accessing' !

basicAt: index
	<primitive 45>
	^ self primitiveFailed
!

basicAt: index put: value
	<primitive 46>
	^ self primitiveFailed
!

basicSize
	<primitive 47>
	^ self primitiveFailed
!

at: index
	^ self basicAt: index
!

at: index put: value
	^ self basicAt: index put: value
!

size
	^self basicSize
!

hash
	"Subclasses should reimplement this, but object number provides a good
	hash for now. "
	<primitive 60>
	^ self primitiveFailed
!

asOop
	"Answer an integer pointer for object."
	<primitive 60>
	^ self primitiveFailed
! !

! Behavior methodsFor: 'Creation'!

new
	^ self basicNew
!

new: aNumber
	^ self basicNew: aNumber
!

basicNew
	<primitive 55>
	^ self primitiveFailed
!

basicNew: aNumber
	<primitive 56>
	^ self primitiveFailed
! !

! Object methodsFor: 'Creation' !

basicNew
	^ self class basicNew
!

basicNew: aNumber
	^ self class basicNew: aNumber
! !

! SmallInteger methodsFor: 'System Primitive'!

asObject
	"Answer an integer pointer for object."
	<primitive 61>
	^ self primitiveFailed
! !

! Object methodsFor: 'System Primitive'!

become: aObject
	"Make one object become another"
	<primitive 57>
	^ self primitiveFailed
!

instVarAt: index
	"Get the instance variable at index"
	<primitive 58>
	^ self primitiveFailed
!

instVarAt: index put: value
	"Set the instance variable at index"
	<primitive 59>
	^ self primitiveFailed
!

someInstance
	"Return first instance of an object, nil if none"
	<primitive 62>
	^ nil
!

nextInstance
	"Return next instance of object, nil if no more"
	<primitive 63>
	^ nil
!

flushCache
	<primitive 107>
! !

! Object methodsFor: 'Message Handling'!

preform: aSymbol
	"Sends the reciever the selector aSymbol"
	<primitive 67>
	^ self primitiveFailed
!

preform: aSymbol with: anObject
	"Sends the reciever the selector aSymbol"
	<primitive 67>
	^ self primitiveFailed
!

preform: aSymbol with: anObject with: secondObject
	"Sends the reciever the selector aSymbol"
	<primitive 67>
	^ self primitiveFailed
!

preform: aSymbol with: anObject with: secondObject with: thirdObject
	"Sends the reciever the selector aSymbol"
	<primitive 67>
	^ self primitiveFailed
!

preform: aSymbol withArguments: anArray
	"Sends the reciever the selector aSymbol"
	<primitive 68>
	^ self primitiveFailed
! !

!Object methodsFor: 'private'!

species
    ^self class
!

yourself
    ^self
!

classNameString
        | name |
        name <- self class name.
        name isNil ifTrue: [ name <- self name , ' class' ].
        ^ name
! !

! BlockContext methodsFor: 'Evaluation'!

value
	" Evaluates the block"
	<primitive 65>
	^ self primitiveFailed
!

value: anObject
	" Evaluates the block with a given value"
	<primitive 65>
	^ self primitiveFailed
!

value: anObject value: secondObject
	" Evaluates the block with the given values"
	<primitive 65>
	^ self primitiveFailed
!

value: anObject value: secondObject value: thirdObject
	" Evaluates the block with the given values"
	<primitive 65>
	^ self primitiveFailed
!

value: anObject value: secondObject value: thirdObject value: fourthObject
	" Evaluates the block with the given values"
	<primitive 65>
	^ self primitiveFailed
!

value: anObject value: secondObject value: thirdObject value: fourthObject
	value: fifthObject
	" Evaluates the block with the given values"
	<primitive 65>
	^ self primitiveFailed
!

valueWithArguments: anArray
	"Sends the reciever the selector aSymbol"
	<primitive 66>
	^ self primitiveFailed
! !

! CompiledMethod methodsFor: 'Evaluation' !

evaluate
	<primitive 100>
	^ self primitiveFailed
! !

! CompiledMethod class methodsFor: 'Creation' !

newMethod: size header: aHeader
	<primitive 64>
	^ self primitiveFailed
! !

! CompiledMethod methodsFor: 'Accessing' !

objectAt: aIndex
	<primitive 53>
	^ self primitiveFailed
!

byteAt: aIndex
	<primitive 103>
	^ self primitiveFailed
!

header
	^ self objectAt: 1
!

literals
	^ self header bitAnd: 16rFF
!

temporaries
	^ (self header bitShift: -8) bitAnd: 16rFF
!

stacksize
	^ (self header bitShift: -16) bitAnd: 16r3FF
!

flags
	^ (self header bitShift: -26) bitAnd: 16rF
!

primitiveOf
	self flags = 16rF
	     ifTrue: [ ^ (self objectAt: (self literals + 1)) bitAnd: 16r1FF ]
	     ifFalse: [ ^ 0 ]
!
	
argcount
	| temp |
	temp <- self flags.
	temp < 16rD ifTrue: [ ^ temp ].
	temp = 16rF 
	     ifTrue: [ ^ ((self objectAt: (self literals + 1)) 
			bitShift: -16) bitAnd: 16rFF ].
	temp = 16rE ifTrue: [ ^ 1 ].
	^ 0
!

description
	^ description
!

" Returns number of bytecodes in method "
bytecodes
	<primitive 105>
	^ self primitiveFailed
! !

! CompiledMethod methodsFor: 'Modifying' !

objectAt: aIndex put: aValue
	<primitive 54>
	^ self primitiveFailed
!

byteAt: aIndex put: aValue
	<primitive 104>
	^ self primitiveFailed
!

description: aMethInfo
	^ description <- aMethInfo
! !

! Boolean methodsFor: 'Copying'!

deepCopy
	^ self
!
	
shallowCopy
	^ self
! !

! True class methodsFor: 'Creating'!

new
	^ true
! !

! False class methodsFor: 'Creating'!

new
	^ false
! !

! True methodsFor: 'Logical Operations'!

& aBoolean
	^ aBoolean
!

| aBoolean
	^ true
!

not 
	^ false
!

eqv: aBoolean
	^ aBoolean 
!

xor: aBoolean
	^ aBoolean not
! !

! False methodsFor: 'Logical Operations'!

& aBoolean
	^ false
!

| aBoolean
	^ aBoolean
!

not 
	^ true
!

eqv: aBoolean
	^ aBoolean not
!

xor: aBoolean
	^ aBoolean 
! !

! True methodsFor: 'Controlling' !

and: aBlock
	^ aBlock value
!

or: aBlock
	^ true
!

ifTrue: trueBlock ifFalse: falseBlock
	^ trueBlock value
!

ifFalse: falseBlock ifTrue: trueBlock
	^ trueBlock value
!

ifTrue: trueBlock
	^ trueBlock value
!

ifFalse: falseBlock
	^ nil
! !

! False methodsFor: 'Controlling' !

and: aBlock
	^ false
!

or: aBlock
	^ aBlock value
!

ifTrue: trueBlock ifFalse: falseBlock
	^ falseBlock value
!

ifFalse: falseBlock ifTrue: trueBlock
	^ falseBlock value
!

ifTrue: trueBlock
	^ nil
!

ifFalse: falseBlock
	^ falseBlock value
! !

! Object methodsFor: 'Copying' !

shallowCopy
	"Make a shallow copy of an object."
	| class newObject |
	class <- self class.
	" Make a new object to hold values"
	class isVariable 
	    ifTrue: [ newObject <- self basicNew: self basicSize ]
	    ifFalse: [ newObject <- self basicNew ].
	" Copy instance variables"
	1 to: class instSize do:
	    [ :i | newObject instVarAt: i put: (self instVarAt: i) ].
	" Copy rest of object if any"
	class isVariable
	     ifTrue: [
		1 to: class basicSize do: 
	    	     [ :i | newObject basicAt: i put: (self basicAt: i) ]
		].
	^ newObject
!

deepCopy
	"Make a true new object"
	| class newObject |
	class <- self class.
	" Make a new object to hold values"
	class isVariable 
	    ifTrue: [ newObject <- self basicNew: self basicSize ]
	    ifFalse: [ newObject <- self basicNew ].
	" Copy instance variables"
	1 to: class instSize do:
	    [ :i | newObject instVarAt: i put: (self instVarAt: i) deepCopy ].
	" Copy rest of object if any"
	class isVariable
	     ifTrue: [
		1 to: class basicSize do: 
	    	     [ :i | newObject basicAt: i put: (self basicAt: i) deepCopy ]
		].
	^ newObject
!

copy
	^self shallowCopy
! !

! Message methodsFor: 'Access' !

selector
	^selector
! !

! Symbol methodsFor: 'Access' !

asString
	^ value
! !

! Object methodsFor: 'Error Handling' !

error: aString
	<primitive 94>
	^ self primitiveFailed
!

doesNotUnderstand: aMessage
	self error:  (self class name) , ' does not understand #',
		aMessage selector asString.
!

primitiveFailed
	self error: 'Primitive Failed'
!

shouldNotImpliment
	self error: 'Should not impliment'
!

subclassResonsibility
	self error: 'Subclass Responsablity'
!

interpStackFault
	self error: 'Attempt to access outside stack'
!

mustBeBoolean
	self error: 'ifTrue: or ifFalse: require boolean value'
! !

! Undefined methodsFor: 'Testing'!

isNil
	^true
!

notNil
	^false
! !

! SmallInteger methodsFor: 'arithmetic' !

+ aNumber
    <primitive 1>
    ^ super + aNumber
!

- aNumber
    <primitive 2>
    ^ super - aNumber
!

* aNumber
    <primitive 3>
    ^ super * aNumber
!

/ aNumber
    <primitive 4>
    ^ super / aNumber
!

\\ aNumber
    <primitive 5>
    ^ super \\ aNumber
!

// aNumber
    <primitive 6>
    ^ super // aNumber

! !

! SmallInteger methodsFor: 'Bit Manipulation'!

bitAnd: aNumber
    <primitive 7>
    self primitiveFail
!

bitOr: aNumber
    <primitive 8>
    self primitiveFail
!

bitXor: aNumber
    <primitive 9>
    self primitiveFail
!

bitShift: aNumber
    <primitive 10>
    self primitiveFail
! !

! SmallInteger methodsFor: 'Comparison' !

= aNumber
    <primitive 11>
    ^ super = aNumber
!

~= aNumber
    <primitive 12>
    ^ super ~= aNumber
    
!

< aNumber
    <primitive 13>
    ^ super < aNumber
!

> aNumber
    <primitive 14>
    ^ super > aNumber
    
!

<= aNumber
    <primitive 15>
    ^ super <= aNumber
!

>= aNumber
    <primitive 16>
    ^ super >= aNumber
    
!

negative
    ^ self < 0
!

positive
    ^ self >= 0
! !

Link comment:
 'I represent simple linked lists.' !

! Link methodsFor: 'basic' !

nextLink
	^next
!

nextLink: aLink
	^next <- aLink
! !

! Association class methodsFor: 'Creating' !

key: aKey value: aValue
	^ self new key: aKey value: aValue
! !

! Association methodsFor: 'Accessing' !

key
	^ key
!

value
	^ value
!

key: aKey
	^ key <- aKey
!

value: aValue
	^ value <- aValue
!

key: aKey value: aValue
	key <- aKey.
	value <- aValue
! !

! Association methodsFor: 'Testing' !

= anAssociation
	^ key = anAssociation key and: [ value = anAssociation value ]
!

hash
	^ key hash + (value hash)
! !

! Association methodsFor: 'printing'!

printOn: aStream
    key printOn: aStream.
    aStream nextPutAll: '->'.
    value printOn: aStream
! !

! Association methodsFor: 'storing'!

storeOn: aStream
    aStream nextPutAll: '(Association key: '.
    self key storeOn: aStream.
    aStream nextPutAll: ' value: '.
    self value storeOn: aStream.
    aStream nextPut: $)
! !


! Set class methodsFor: 'Instance Creation'!

new
	^ self new: 32
!

new: anInteger
	^ (super new: anInteger) setTally
! !

! Set methodsFor: 'Accessing' !

at: index
	self errorNotKeyed
!

at: index put: anObject
	self errorNotKeyed
!

add: newObject
	| index |
	newObject isNil ifTrue: [ ^ newObject ].
	index <- self findObjectIndex: newObject.
	(self basicAt: index) isNil
	    ifTrue: [ self basicAt: index put: newObject.
		      tally <- tally + 1 ].
	^newObject
!

remove: anObject 
	| index |
	index <- self findIndexOrNil: anObject ifFull: [ nil ].
	index notNil ifTrue: [ 
		tally <- tally - 1.
		self rehashAfterIndex: index
	].
	^ anObject
!

remove: anObject ifAbsent: aBlock
	| index |
	index <- self findIndexOrNil: anObject ifFull: [ nil ].
	index isNil ifTrue: [ ^ aBlock value ].
	tally <- tally - 1.
	self rehashAfterIndex: index.
	^ anObject
!

size
	^ tally
! !

! Set methodsFor: 'testing' !

includes: anObject
	| index |
	index <- self findIndexOrNil: anObject ifAbsent: [ ^ false ].
	^ (self basicAt: index) notNil
!

isEmpty
	^ tally == 0
!

occurrencesOf: anObject
	anObject isNil ifTrue: [ ^ 1 ].
	(self includes: anObject) ifTrue: [ ^ 1 ] ifFalse: [ ^ 0 ]
! !

! Set methodsFor: 'Enumeration' !

do: aBlock
	"Call block for each non-nil element of set"
	| element index size |
	size <- self basicSize.
	" We don't have interval defined so use a loop "
	index <- 1.
	[ index < size ] whileTrue: [
	   element <- self basicAt: index.
	   element notNil ifTrue: [ aBlock value: element ].
	   index <- index + 1 
	].
! !

! Set methodsFor: 'private'!

setTally
	tally <- 0
!

findIndexOrNil: anObject ifFull: aBlock
	" Try and find the object in the array, return index or nil"
	| index wrap size key |
	size <- self basicSize.
	index <- 1 + (anObject hash \\ (size - 1)).
	wrap <- false.
	[ true ] whileTrue: [
		key <- self basicAt: index.
		(key isNil  or: [key = anObject ] ) ifTrue: [ ^ index ].
 		index <- index + 1.
		index > size ifTrue: [
			wrap ifTrue: [ ^ aBlock value ].
			index <- 1.
			wrap <- true.
		]
	]
!

findObjectIndex: anObject
	"Finds an object, if no space, grows Set."
	^ self findIndexOrNil: anObject ifFull: [
		 self grow.
		 ^ self findIndexOrNil: anObject ifFull: [ ^ nil ]
		].
!

rehashAfterIndex: index
	"Adjust objects if after index"
	| i size count element |
	i <- index.
	size <- self basicSize.
	count <- size.
	self basicAt: index put: nil.
	[ count <- count - 1.
	  i <- 1 + (i \\ size).
	  element <- self basicAt: i.
	  count > 0 and: [ element notNil ] ]
	    whileTrue:
		[ self basicAt: i put: nil.
		  self basicAt: (self findObjectIndex: element) put: element ].
	^ self
!

grow
	| newSet |
	newSet <- self species new: self basicSize + self growSize.
	self do: [ :element | newSet add: element ].
	^ self become: newSet
!

growSize
	^ 32
! !

! Dictionary methodsFor: 'Accessing' !

at: key
	^ self at: key ifAbsent: [ self errorKeyNotFound ]
!

at: key ifAbsent: aBlock
	| index temp |
	index <- self findIndexOrNil: key ifFull: [ nil ].
	index isNil ifTrue: [ ^ aBlock value ]. 
	temp <- self basicAt: index.
	temp isNil ifTrue: [ ^ aBlock value ].
	^ temp value 
!

at: key put: value
	| index element |
	index <- self findObjectIndex: key.
	element <- self basicAt: index.
	element isNil
	   ifTrue:
		[ self basicAt: index put: (Association key: key value: value).
		  tally <- tally + 1 ]
		" The element already exists, just update it's value "
	   ifFalse:
		[ element value: value ].
	^ value
!


add: anAssociation
	| index element |
	index <- self findObjectIndex: anAssociation key.
	element <- self basicAt: index.
	element isNil
	    ifTrue: [ self basicAt: index put: anAssociation.
		      tally <- tally + 1 ]
	    ifFalse: [ element value: anAssociation value].
	^anAssociation
!

remove: anObject
	self shouldNotImplement
!

remove: anObject ifAbsent: aBlock
	self shouldNotImplement
!

removeAssociation: anAssociation
	self removeKey: anAssociation key ifAbsent: [].
	^ anAssociation
!

removeKey: aKey ifAbsent: aBlock
	| index assoc |
	index <- self findIndexOrNil: aKey ifAbsent: [ ^ aBlock value ].
	assoc <- self basicAt: index.
	tally <- tally - 1.
	self basicAt: index put: nil.
	self rehashAfterIndex: index.
	^ assoc value
! !

! Dictionary methodsFor: 'Enumeration' !

associationsDo: aBlock
	super do: [ :assoc | aBlock value: assoc ]
!

do: aBlock
	self associationsDo: [ :assoc | aBlock value: assoc value ]
! !

! Dictionary methodsFor: 'private' !

findIndexOrNil: aKey ifFull: aBlock
	" Try and find the object in the array, return index or nil"
	| index wrap size assoc |
	size <- self basicSize.
	index <- 1 + (aKey hash \\ (size - 1)).
	wrap <- false.
	[ true ] whileTrue: [
		assoc <- self basicAt: index.
		assoc isNil or: [assoc key = aKey ] ifTrue: [ ^ index ].
		index <- index + 1.
		index > size ifTrue: [
			wrap ifTrue: [ ^ aBlock value ].
			index <- 1.
			wrap <- true.
		]
	]
!

findObjectIndex: aKey
	"Finds an object, if no space, grows Set."
	^ self findIndexOrNil: aKey ifFull: [
		 self grow.
		 ^ self findIndexOrNil: aKey ifFull: [ ^ nil ]
		].
!

rehashAfterIndex: index
	"Adjust objects if after index"
	| i size count element |
	i <- index.
	size <- self basicSize.
	count <- size.
	self basicAt: index put: nil.
	[ count <- count - 1.
	  i <- 1 + (i \\ size).
	  element <- self basicAt: i.
	  count > 0 and: [ element notNil ] ]
	    whileTrue:
		[ self basicAt: i put: nil.
		  self basicAt: (self findObjectIndex: element) put: element ].
	^ self
!

grow
	| newDict |
	newDict <- self species new: self basicSize + self growSize.
	self associationsDo: [ :element | newDict add: element ].
	^ self become: newDict
! !

! String methodsFor: 'Conversion'!

asSymbol
	<primitive 91>
! !

! String methodsFor: 'operating' !

, aString
	"Join aString onto end of string"
	| newString len1 index index2 len |
	" Determine length of new string "
	len1 <- self size.
	len <- len1 + (aString size).
	" Make new string "
	newString <- String new: len.
	index <- 1.
	index2 <- 1.
	" Copy first string to new location "
	[ index <= len1 ] whileTrue: [
		newString at: index put: (self at: index ).
		index <- index + 1 ].
	" Now copy over second string "
	[ index <= len ] whileTrue: [
		newString at: index put: (aString at: index2 ).
		index2 <- index2 + 1 .
		index <- index + 1 ].
	^ newString
! !

! String methodsFor: 'Accessing'!

at: aIndex
	<primitive 48>
	^ self primitiveFailed
!

at: aIndex put: aChar
	<primitive 49>
	^ self primitiveFailed
! !

! Behavior methodsFor: 'Class Heirarchy' !

addSubclass: aClass
        "Adds a subclass to set of subclasses"
	subclasses isNil ifTrue:
		[ subclasses <- Set new ].
        subclasses add: aClass
!

removeSubclass: aClass
        "Remove a class from list of classes subclasses."
        subclasses remove: aClass
!

superclass: aClass
	^ superclass <- aClass
! !

! Behavior methodsFor: 'Accessing class heirarchy'!

subclasses
        "Return a set of immediate subclasses"
        ^ subclasses
!

superclass
	^superclass
! !

! Behavior methodsFor: 'Testing the form of instances'!

instSize
	^ flags // 8
!

isPointer
	^ ( flags bitAnd: 1 ) ~= 0
!

isBits
	^ ( flags bitAnd: 1 ) == 0
!

isBytes
	^ ( flags bitAnd: 2) ~= 0
!

isWords
	^ ( flags bitAnd: 2) == 0
!

isFixed
	^ ( flags bitAnd: 4) == 0
!

isVariable
	^ ( flags bitAnd: 4) ~= 0
! !

! Class methodsFor: 'Accessing'!

name
	^ name
!

instVarNames
	^ vars
!

allInstVarNames
    | svars index index2 newarray |
    svars <- superclass allInstVarNames.
    newarray <- (vars size) + (svars size).
    index <- 1.
    [ index < (svars size) ] whileTrue:
	[ newarray at: index put: (svars at: index).
	  index <- index + 1. ].
    index2 <- 1.
    [ index2 < (vars size) ] whileTrue:
	[ newarray at: index put: (vars at: index2).
	  index <- index + 1. index2 <- index2 + 1. ].
    ^ newarray
!

comment
	^ comment
!

category
	^ category
! !

! Class methodsFor: 'Modification' !

instVarNames: aString
    | isize cl |
    vars <- self StringasArray: aString.
    isize <- vars size.
    cl <- self superclass.
    cl notNil ifTrue: [ isize <- cl instSize + isize ].
    flags isNil ifTrue: [ flags <- isize * 8 ]
                ifFalse: [ flags <- (isize * 8) + (flags bitAnd: 7)].
    ^ vars
!

classVarNames: aString
    | names newdict index n |
    newdict <- Dictionary new.
    classvars isNil ifTrue: [ classvars <- newdict ].
    names <- self StringasArray: aString.
    index <- 1.
    [ index <= (names size) ] whileTrue: [
	n <- names at: index.
        newdict add: (classvars at: (n asSymbol) ifAbsent:
                        [ Association key: (n asSymbol) value: nil ]).
	index <- index + 1].
    classvars <- newdict.
    ^ newdict
!

comment: aString
	^ comment <- aString
!

category: aString
	^ category <- aString
!

name: aString
	^ name <- aString
!

instFlags: variableBoolean
	words: wordBoolean
	pointers: pointerBoolean
	| temp |
	flags isNil ifTrue: [ temp <- 0 ]
		    ifFalse: [ temp <- flags bitAnd: ( 7 negated)].
	pointerBoolean
	  ifTrue: [ temp <- temp bitOr: 1 ]
	  ifFalse: [
	     wordBoolean ifFalse: [ temp <- temp bitOr: 2 ]].
	variableBoolean ifTrue: [ temp <- temp bitOr: 4 ].
	^ flags <- temp
! !

! Class methodsFor: 'Instance Creation'!

subclass: classNameString instanceVariableNames: stringInstVarNames
       classVariableNames: stringClassVarNames
       poolDictionaries: stringPoolNames
       category: categoryNameString
	| newMeta |
	newMeta <- self metaclassFor: classNameString.
	^ newMeta name: classNameString
	          enviorment: Smalltalk
	          subclassOf: self
	          instanceVariableNames: stringInstVarNames
	          variable: false
	          words: false
	          pointers: true
	          classVariableNames: stringClassVarNames
	          poolDictionaries: stringPoolNames
	          category: categoryNameString
		  comment: nil
		  changed: nil
!

variableSubclass: classNameString instanceVariableNames: stringInstVarNames
       classVariableNames: stringClassVarNames
       poolDictionaries: stringPoolNames
       category: categoryNameString
	| newMeta |
	newMeta <- self metaclassFor: classNameString.
	^ newMeta name: classNameString
	          enviorment: Smalltalk
	          subclassOf: self
	          instanceVariableNames: stringInstVarNames
	          variable: true
	          words: false
	          pointers: true
	          classVariableNames: stringClassVarNames
	          poolDictionaries: stringPoolNames
	          category: categoryNameString
		  comment: nil
		  changed: nil
!

variableByteSubclass: classNameString instanceVariableNames: stringInstVarNames
       classVariableNames: stringClassVarNames
       poolDictionaries: stringPoolNames
       category: categoryNameString
	| newMeta |
	newMeta <- self metaclassFor: classNameString.
	^ newMeta name: classNameString
	          enviorment: Smalltalk
	          subclassOf: self
	          instanceVariableNames: stringInstVarNames
	          variable: true
	          words: false
	          pointers: false
	          classVariableNames: stringClassVarNames
	          poolDictionaries: stringPoolNames
	          category: categoryNameString
		  comment: nil
		  changed: nil
!

variableWordSubclass: classNameString instanceVariableNames: stringInstVarNames
       classVariableNames: stringClassVarNames
       poolDictionaries: stringPoolNames
       category: categoryNameString
	| newMeta |
	newMeta <- self metaclassFor: classNameString.
	^ newMeta name: classNameString
	          enviorment: Smalltalk
	          subclassOf: self
	          instanceVariableNames: stringInstVarNames
	          variable: true
	          words: true
	          pointers: false
	          classVariableNames: stringClassVarNames
	          poolDictionaries: stringPoolNames
	          category: categoryNameString
		  comment: nil
		  changed: nil
!

byteSubclass: classNameString instanceVariableNames: stringInstVarNames
       classVariableNames: stringClassVarNames
       poolDictionaries: stringPoolNames
       category: categoryNameString
	| newMeta |
	newMeta <- self metaclassFor: classNameString.
	^ newMeta name: classNameString
	          enviorment: Smalltalk
	          subclassOf: self
	          instanceVariableNames: stringInstVarNames
	          variable: false
	          words: false
	          pointers: false
	          classVariableNames: stringClassVarNames
	          poolDictionaries: stringPoolNames
	          category: categoryNameString
		  comment: nil
		  changed: nil
!

wordSubclass: classNameString instanceVariableNames: stringInstVarNames
       classVariableNames: stringClassVarNames
       poolDictionaries: stringPoolNames
       category: categoryNameString
	| newMeta |
	newMeta <- self metaclassFor: classNameString.
	^ newMeta name: classNameString
	          enviorment: Smalltalk
	          subclassOf: self
	          instanceVariableNames: stringInstVarNames
	          variable: false
	          words: true
	          pointers: false
	          classVariableNames: stringClassVarNames
	          poolDictionaries: stringPoolNames
	          category: categoryNameString
		  comment: nil
		  changed: nil
! !

! Class methodsFor: 'Private'!

metaclassFor: classNameString
	| aClass |
	aClass <- Smalltalk at: classNameString asSymbol ifAbsent: [ nil ].
	aClass isNil ifTrue:
		[ ^ MetaClass subclassOf: self class ].
	^ aClass class
!

StringasArray: aString
    | len str index index1 index2 c offset array |
    len <- aString size.
    len = 0 ifTrue: [ ^ Array new: 0.  ].
    index <- 1.
    index1 <- 1.
    offset <- 0.
    [ index <= len ] whileTrue: [
	c <- aString at: index.
	c = $  ifTrue: [
	           index1 ~= index ifTrue: [ offset <- offset + 1. ].
		   index1 <- index + 1 ].
        index <- index + 1.
    ].
    index1 ~= index ifTrue: [ offset <- offset + 1. ].
    array <- Array new: offset.
    offset = 0 ifTrue: [ ^ array ].
    offset <- 1.
    index <- 1.
    index1 <- 1.
    [ index <= len ] whileTrue: [
	c <- aString at: index.
	c = $  ifTrue: [
	           index1 ~= index ifTrue: [
			" Build a new string "
			str <- String new: (index - index1).
			index2 <- 1.
			[ index1 < index ] whileTrue: [
				str at: index2 put: ( aString at: index1).
				index2 <- index2 + 1.
				index1 <- index1 + 1
			].
			array at: offset put: str.
			offset <- offset + 1
		   ].
		   index1 <- index + 1 ].
                index <- index + 1.
    ].
    index1 <= len ifTrue: [
	" Build a new string "
	str <- String new: (index - index1).
	index2 <- 1.
	[ index1 < index ] whileTrue: [
		str at: index2 put: ( aString at: index1).
		index2 <- index2 + 1.
		index1 <- index1 + 1
	 ].
	 array at: offset put: str.
	 offset <- offset + 1
    ].
    ^array
! !

! MetaClass class methodsFor: 'Creation'!

subclassOf: aClass
	| newMeta |
	newMeta <- self new.
	newMeta superclass: aClass.
	^ newMeta
! !

! MetaClass methodsFor: 'Accesss' !

instanceClass
	^ instanceClass
!

instanceClass: aClass
	^ instanceClass <- aClass
! !

! MetaClass methodsFor: 'Basic'!

name: newName
	enviorment: aSystemDictionary
	subclassOf: superClass
	instanceVariableNames: stringOfInstVarNames
	variable: variableBoolean
	words: wordsBoolean
	pointers: pointersBoolean
	classVariableNames: stringOfClassVarNames
	poolDictionaries: stringOfPoolNames
	category: categoryName
	comment: commentString
	changed: changed
	| aClass className |

	className <- newName asSymbol.
	aClass <- aSystemDictionary at: className ifAbsent: [ nil ].
	aClass isNil ifTrue: [
		^ self  newMeta: newName
			enviorment: aSystemDictionary
			subclassOf: superClass
			instanceVariableNames: stringOfInstVarNames
			variable: variableBoolean
			words: wordsBoolean
			pointers: pointersBoolean
			classVariableNames: stringOfClassVarNames
			poolDictionaries: stringOfPoolNames
			category: categoryName
			comment: commentString
			changed: changed
	].
	" Don't modify existing class too much "
	name <- newName.
	instanceClass <- aClass.
	" Update subclass chain "
	aClass superclass notNil ifTrue: [
		aClass superclass ~= superClass ifTrue:
		      [ aClass superclass removeSubclass: aClass
			superClass addSubclass: aClass ].
	].
	aClass superclass: superClass.
	superClass notNil
	    ifTrue: [ aClass class superclass: superClass class ].
	aClass name: newName.
	aClass instFlags: variableBoolean words: wordsBoolean
		pointers: pointersBoolean.
	aClass instVarNames: stringOfInstVarNames.
        classvars <- aClass classVarNames: stringOfClassVarNames.
	aClass category: categoryName.
	aClass comment: commentString.
	^ aClass
!
				
newMeta: newName
	enviorment: aSystemDictionary
	subclassOf: superClass
	instanceVariableNames: stringOfInstVarNames
	variable: variableBoolean
	words: wordsBoolean
	pointers: pointersBoolean
	classVariableNames: stringOfClassVarNames
	poolDictionaries: stringOfPoolNames
	category: categoryName
	comment: commentString
	changed: changed
	| aClass |
	" Fill in the metaclass first "
	vars <- Class instVarNames.
	" Set instance size before we go too far "
        flags <- (Class instSize * 8) + 1.
	name <- newName.
	aClass <- self new.
	instanceClass <- aClass.
	" Now fill in the class "
	aClass superclass: superClass.
	aClass name: newName.
	aClass instFlags: variableBoolean words: wordsBoolean
		pointers: pointersBoolean.
	aClass instVarNames: stringOfInstVarNames.
        classvars <- aClass classVarNames: stringOfClassVarNames.
	superClass addSubclass: aClass.
	aClass category: categoryName.
	aClass comment: commentString.
	" Lastly add it into the system symbol table"
	aSystemDictionary at: (newName asSymbol) put: aClass.
	^ aClass
! !

Object subclass: 'File' instanceVariableNames: 'name mode position'
       classVariableNames: '' poolDictionaries: '' category: nil!

!File class methodsFor: 'creation' !

open: aName mode: aMode ifFail: aBlock
	| file |
	^ self open: aName mode: aMode ifFail: 
		[ ^ self error: 'Failed to open ''', aName, '''' ]
!

open: aName mode: aMode ifFail: aBlock
	| file |
	file <- self new setName: aName mode: aMode.
	file open ifFalse: [ ^ aBlock value ].
	^ file
!

fromArray: aArray
	| n m pos nFile |
	n <- aArray at: 1.
	m <- aArray at: 2.
	pos <- aArray at: 3.
	nFile <- self new setName: n mode: m.
	nFile position: pos.
	^ nFile
! !

!File methodsFor: 'basic' !

setName: aName mode: aMode
	name <- aName.
	mode <- aMode.
	position <- 0.
!

name
	^name
!

mode
	^ mode
!

position
	^ position
!

position: anInteger
	position <- anInteger
!

skip: anInteger
	position <- position + anInteger
!

atEnd
	^ position = (self size)
! !

!File methodsFor: 'control' !

open
	<primitive 80>
	^ false
!

close
	<primitive 81>

! !

!File methodsFor: 'accesss'!

next
	<primitive 84>
	^ 0 asCharacter
!

read: anArray
	<primitive 86>
!

nextPut: anInteger
	<primitive 85>
!

write: anArray
	<primitive 87>
!

size
	<primitive 88>
! !

