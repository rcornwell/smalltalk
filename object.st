" Last bits and peices of smalltalk system "

" $Id: $ "

"
 $Log: $
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
	aStream nextPutAll: first ;
		nextPutAll: name
!

print
	| str |
	str <- self printString.
	str DumpObject
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

!Object methodsFor: 'Shortcut' !

-> anObject
	^ Association key: self value: anObject
! !

!String methodsFor: 'System'!

snapShot
        <primitive 79>
! !

'smalltalk.sti' snapShot !

(3 + 4) print !
