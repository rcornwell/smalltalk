" Last bits and peices of smalltalk system "

" $Id: object.st,v 1.4 2001/01/17 02:33:16 rich Exp rich $ "

"
 $Log: object.st,v $
 Revision 1.4  2001/01/17 02:33:16  rich
 Code cleanup
 Rewrote executeLoop.

 Revision 1.3  2000/08/27 17:08:55  rich
 Fixed some typos.
 Added last of code to link in compiler.

 Revision 1.2  2000/02/01 18:09:58  rich
 Changed print to use CharStream class.
 Fixed bugs.
 Added System class.

 Revision 1.1  1999/09/02 15:57:59  rich
 Initial revision

"

!

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

! Object methodsFor: 'Creation' !

basicNew
	^ self class basicNew
!

basicNew: aNumber
	^ self class basicNew: aNumber
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

! Object methodsFor: 'private'!

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

! Object methodsFor: 'Printing' !

printString
	"Return a string representation of self"
	| aStream |
	aStream <- WriteStream on: (String new: 0).
	self printOn: aStream.
	^ aStream contents
!

printOn: aStream
	"Print the objects class name."
	| name first |
	name <- self classNameString.
	first <- (name at: 1) isVowel ifTrue: [ 'an ' ] ifFalse: [ 'a ' ]. 
	aStream nextPutAll: first.
	aStream	nextPutAll: name
!

print
	stdout nextPutAll: (self printString).
	stdout nl.
	^ self
!

storeString
	"Return a string representation of self"
	| aStream |
	aStream <- WriteStream on: (String new: 0).
	self storeOn: aStream.
	^ aStream contents
!

storeOn: aStream
	"Store the object onto the stream."
	| class semi |
	class <- self class.
	aStream nextPut: $(.
	aStream nextPutAll: self classNameString.
	class isVariable 
	    ifTrue: [ aStream nextPutAll: ' basicNew: '.
		      self basicSize printOn: aStream ]
	    ifFalse: [ aStream nextPutAll: ' basicNew' ].
	semi <- false.
	1 to: class instSize do:
	    [ :i | aStream nextPutAll: ' instVarAt: '.
		   i printOn: aStream.
		   aStream nextPutAll: ' put: '.
		   (self instVarAt: i) storeOn: aStream.
		   aStream nextPut: $;.
		   semi <- true ].
	class isVariable ifTrue:
	    [ 1 to: self basicSize do:
		[ :i | aStream nextPutAll: ' basicAt: '.
		   i printOn: aStream.
		   aStream nextPutAll: ' put: '.
		   (self basicAt: i) storeOn: aStream.
		   aStream nextPut: $;.
		   semi <- true ]
	     ].
	semi ifTrue: [ aStream nextPutAll: ' self' ].
	aStream nextPut: $)
		   
! !

! Object methodsFor: 'Shortcut' !

-> anObject
	^ Association key: self value: anObject
! !

! Message methodsFor: 'Access' !

selector
	^selector
! !

! Undefined methodsFor: 'Testing'!

isNil
	^true
!

notNil
	^false
! !

! Undefined methodsFor: 'Printing' !

printString
	"Return a string representation of self"
	^ 'nil'
!

printOn: aStream
	"Print the objects class name."
	aStream nextPutAll: 'nil'
!

storeString
	"Return a string representation of self"
	^ 'nil'
!

storeOn: aStream
	"Store the object onto the stream."
	aStream put: 'nil'.
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

Object subclass: 'System' instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: nil
!

System comment: 'I handle system specific actions.' !

! System class methodsFor: 'System' !

coreUsed
	<primitive 75>
!

freeCore
	<primitive 76>
!

oopsLeft
	<primitive 77>
!

quit
	<primitive 78>
!

DoSnapShot: aName
	<primitive 79>
!

snapShot: aName
	^ self DoSnapShot: aName
!

stackTrace
	<primitive 99>
! !

" This method can't go before since it needs Compile object. " !

! Stream methodsFor: 'file I/O' !

fileIn
	| aString sawExclaim |
	[ self atEnd] whileFalse: [
	    sawExclaim <- self peekFor: $!!.
	    aString <- self nextChunk.
	    sawExclaim
	       ifFalse: [ Compiler evaluate: aString]
	       ifTrue: [ (Compiler evaluate: aString) fileInFrom: self]]
!

executeLoop
	| aString chunk char |
	stderr nextPutAll: 'Smalltalk Started'.
	stderr nl.
	chunk <- WriteStream on: (String new: 0).
	[ self atEnd] whileFalse: [
	    char <- self next.
	    char == $!!
	       ifTrue: [
		    char <- self next.
		    ((Character nl == char) or: [ (Character cr == char) ])
		        ifTrue: [
			    aString <- chunk contents.
	    		    Compiler evaluate: aString.
	    		    chunk <- WriteStream on: (String new: 0). 
	    		    stderr nextPutAll: 'Ready'.
			    stderr nl. ]
		        ifFalse: [
			    chunk nextPut: $!!.
			    chunk nextPut: char.
		     ]]
	       ifFalse: [
		    ((Character nl == char) or: [ (Character cr == char)])
		        ifFalse: [ chunk nextPut: char ]
			ifTrue: [ chunk nextPut: (Character space) ]
	      ]
	]
! !

! Class methodsFor: 'compiler' !

methodsFor: aCategory
      ^ ClassCategoryReader for: self category: aCategory
! !

