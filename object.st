" Last bits and peices of smalltalk system "

" $Id: object.st,v 1.1 1999/09/02 15:57:59 rich Exp rich $ "

"
 $Log: object.st,v $
 Revision 1.1  1999/09/02 15:57:59  rich
 Initial revision

"

!
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
	first <- name first isVowel ifTrue: [ 'an ' ] ifFalse: [ 'a ' ]. 
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

!Object methodsFor: 'Shortcut' !

-> anObject
	^ Association key: self value: anObject
! !

Object subclass: 'System' instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: nil
!

System comment: 'I handle system specific actions.' !

!System class methodsFor: 'System' !

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

!Stream methodsFor: 'file I/O' !
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
	| aString |
	stdout nextPutAll: 'Smalltalk Loaded'.
	stdout nl.
	[ self atEnd] whileFalse: [
	    stdout nextPutAll: 'Ready'.
	    stdout nl.
	    aString <- self nextChunk.
	    stderr nextPutAll: 'Executing: '.
	    stderr nextPutAll: aString.
	    stderr nextPutAll: ':'.
	    stderr nl.
	    Compiler evaluate: aString.
	]
! !

(System snapShot: 'smalltalk.sti') .
 stdin executeLoop 
!

