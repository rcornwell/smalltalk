" Last bits and peices of smalltalk system "

" $Id: object.st,v 1.3 2000/08/27 17:08:55 rich Exp rich $ "

"
 $Log: object.st,v $
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
	| aString chunk char |
	stderr nextPutAll: 'Smalltalk Started'.
	stderr nl.
	chunk <- WriteStream on: (String new: 0).
	[ self atEnd] whileFalse: [
	    char <- self next.
	    char == $!!
	       ifTrue: [
		    char <- self next.
		    (Character nl == char) or: [ (Character cr == char) ]
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
		    (Character nl == char) or: [ (Character cr == char) ]
		        ifFalse: [ chunk nextPut: char ]
			ifTrue: [ chunk nextPut: (Character space) ]
	      ]
	]
! !

!Class methodsFor: 'compiler' !

methodsFor: aCategory
      ^ ClassCategoryReader for: self category: aCategory
! !

(Smalltalk at: #loading ifAbsent: [nil]) isNil
  ifTrue: [
	" First time through, define and reload self with native compiler."
	stderr nextPutAll: 'Base Loaded'.
	stderr nl.
	Smalltalk at: #loading put: true.
	"FileStream fileIn: 'object.st'. "
	stderr nextPutAll: 'Saving image'.
	stderr nl.
	Smalltalk removeKey: #loading ifAbsent: [nil].
	(System snapShot: 'smalltalk.sti')
		 ifTrue: [ System quit ]
		" When we come back after reload, run execute loop. "
		 ifFalse: [ stdin executeLoop ]
].
System quit.

!
!

