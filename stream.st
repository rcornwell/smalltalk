" Methods for Class stream and all it's subclasses"

" $Id: stream.st,v 1.3 2000/08/27 17:08:37 rich Exp rich $ "

"
 $Log: stream.st,v $
 Revision 1.3  2000/08/27 17:08:37  rich
 Fixed bugs in reading chunk from stream.

 Revision 1.2  2000/02/01 18:10:04  rich
 Fixed some compile errors.
 Added chunk read/write code.
 Added CharStream class.
 Use primitives for Next, NextPut, and atEnd.
 Fixed errors.

 Revision 1.1  1999/09/02 15:57:59  rich
 Initial revision

"

Object subclass: 'Stream' instanceVariableNames: 'contents'
       classVariableNames: '' poolDictionaries: '' category: nil
!

!Stream methodsFor: 'accessing-reading'!

next
    self subclassResponsibility
!

next: anInteger
    self subclassResponsibility
!

nextMatchFor: anObject
    ^anObject = self next
!

contents
    self subclassResponsibility
! !


!Stream methodsFor: 'accessing-writing'!

nextPut: anObject
    self subclassResponsibility
!

nextPutAll: aCollection
    aCollection do: [ :element | self nextPut: element ].
    ^aCollection
!

next: anInteger put: anObject
    anInteger timesRepeat: [ self nextPut: anObject ].
    ^anObject
! !

!Stream methodsFor: 'testing'!

atEnd
    self subclassResponsibility
! !

!Stream methodsFor: 'enumerating'!

do: aBlock
    [self atEnd] whileFalse: [aBlock value: self next ]
! !

!Stream methodsFor: 'printing'!

print: anObject
    anObject printOn: self
! !

!Stream methodsFor: 'storing'!

store: anObject
    anObject storeOn: self
! !



Stream subclass: 'PositionableStream'
       instanceVariableNames: 'position endPtr'
       classVariableNames: '' poolDictionaries: '' category: nil
!

!PositionableStream class methodsFor: 'instance creation'!

on: aCollection
    ^(self new initCollection: aCollection)
!

on: aCollection from: firstIndex to: lastIndex
    ^self on: (aCollection copyFrom: firstIndex to: lastIndex)

! !

!PositionableStream methodsFor: 'accessing-reading'!


next: anInteger
    "Returns a collection of the same type that the stream accesses, that has
    the next anInteger elements from the stream."
    | collection number  |
    number <- anInteger min: (endPtr - position).
    collection <- contents species new: number.
    1 to: number do:
        [ :i | collection at: i put: self next ].
    ^collection
!

peek
    "Returns the next element of the stream without moving the pointer.
    Returns nil when at end of stream."
    | peekValue |
    self atEnd ifTrue: [ ^nil ].
    peekValue <- self next.
    self skip: -1.
    ^peekValue    
!

peekFor: anObject
    "Returns true and gobbles the next element from the stream of it is
    equal to anObject, returns false and doesn't gobble the next element
    if the next element is not equal to anObject."
    (self peek) = anObject
        ifTrue: [ self next.
                  ^true ]
        ifFalse: [ ^false ]
!

contents
    "Returns a collection of the same type that the stream accesses, up to 
    and including the final element."
    ^contents copyFrom: 1 to: endPtr
!

reverseContents
    "Returns a collection of the same type that the stream accesses, up to 
    and including the final element, but in reverse order."
    | newCollection |
    newCollection <- contents species new: endPtr.
    1 to: endPtr do:
        [ :i | newCollection at: i put: (contents at: endPtr - i + 1) ].
    ^newCollection
! !

!PositionableStream methodsFor: 'testing'!

atEnd
    <primitive 52>
    ^position > endPtr
!

isEmpty
    ^endPtr = 0
! !


!PositionableStream methodsFor: 'positioning'!

position
    ^position
!

position: anInteger
    (anInteger between: 1 and: endPtr)
        ifTrue: [ position <- anInteger ]
        ifFalse: [ ^self error: 'position out of range' ]
!

reset
    position <- 1
!

setToEnd
    position <- endPtr + 1
!

skip: anInteger
    position <- (position + anInteger max: 1) min: endPtr
!

skipTo: anObject
    "Moves the current position to after the next occurrence of anObject
    and returns true if anObject was found.  If anObject doesn't exist, the 
    position is unchanged, and false is returned."
    | curPos |
    curPos <- self position.
    [ self atEnd ] whileFalse:
        [ (self nextMatchFor: anObject) ifTrue: [ ^true ] ].
    self position: curPos.
    ^false    

! !

!PositionableStream methodsFor: 'private'!

initCollection: aCollection
    contents <- aCollection.
    position <- 1.
    endPtr <- contents size
! !

PositionableStream subclass: 'ReadStream' instanceVariableNames: ''
                   classVariableNames: '' poolDictionaries: '' category: nil!

!ReadStream methodsFor: 'accessing-reading'!

next
    | element |
    <primitive 50>
    self atEnd ifTrue: [ ^self error: 'end of stream reached' ].
    element <- contents at: position.
    position <- position + 1.
    ^element
! !

!ReadStream methodsFor: 'accessing-writing'!

nextPut: anObject
    self shouldNotImpliment
! !

PositionableStream subclass: 'WriteStream' instanceVariableNames: 'maxSize'
                   classVariableNames: '' poolDictionaries: '' category: nil!

!WriteStream class methodsFor: 'instance creation'!

on: aCollection
    ^ self new initCollection: aCollection.
!

with: aCollection
    | stream |
    stream <- self on: aCollection.
    stream moveToEnd.
    ^stream
!

with: aCollection from: firstIndex to: lastIndex
    | stream |
    stream <- self on: aCollection fromFirstIndex to: lastIndex.
    stream moveToEnd.
    ^stream
! !

!WriteStream methodsFor: 'accessing-reading'!

next
    self shouldNotImpliment
! !

!WriteStream methodsFor: 'accessing-writing'!

nextPut: anObject
    <primitive 51>
    position > maxSize ifTrue: [ self growCollection ].
    contents at: position put: anObject.
    position > endPtr ifTrue: [ endPtr <- position ].
    position <- position + 1.
    ^anObject
! !


!WriteStream methodsFor: 'character writing'!

cr
    self nextPut: Character cr
!

nl
    self nextPut: Character nl
!

crTab
    self cr.
    self tab
!

nlTab
    self nl.
    self tab
!

space
    self nextPut: Character space
!

tab
    self nextPut: Character tab
! !


!WriteStream methodsFor: 'private methods'!

initCollection: aCollection
    contents <- aCollection.
    endPtr <- 0.
    maxSize <- aCollection size.
    position <- 1
!

moveToEnd
    endPtr <- contents size.
    self setToEnd
!

growCollection
    contents grow.
    maxSize <- contents size
! !

!PositionableStream methodsFor: 'accessing-reading'!

" We need to put this here since it uses WriteStream, which was not
 defined before"
upTo: anObject
    "Returns a collection of the same type that the stream accesses, up to 
    but not including the object anObject.  Returns the entire rest of the 
    stream's contents if anObject is not present."
    | newStream |
    newStream <- WriteStream on: (contents species new: 0).
    [ self atEnd or: [ self peek ~= anObject ] ] whileFalse:
        [ newStream nextPut: (self next) ].
    ^newStream contents
! !

WriteStream subclass: 'ReadWriteStream' instanceVariableNames: ''
            classVariableNames: '' poolDictionaries: '' category: nil!

!ReadWriteStream class methodsFor: 'instance creation'!

on: aCollection
    | stream |
    stream <- (super on: aCollection).
    stream useWholeStream.
    ^stream
! !

!ReadWriteStream methodsFor: 'accessing-reading'!

next
    | element |
    <primitive 50> 
    self atEnd ifTrue: [ ^self error: 'end of stream reached' ].
    element <- contents at: position.
    position <- position + 1.
    ^element
! !


!ReadWriteStream methodsFor: 'private'!

useWholeStream
    "Makes sure that the contents message to this object returns the
     whole contents, not just that which has been written so far."
    endPtr <- contents size
! !

ReadWriteStream subclass: 'CharStream' 
       instanceVariableNames: 'stream mode'
       classVariableNames: '' poolDictionaries: '' category: nil
!

!CharStream class methodsFor: 'creation'!

on: aStream
    ^ super new stream: aStream
! !

!CharStream methodsFor: 'accessing-writing'!

nextPut: anObject
    contents isNil ifTrue: [ contents <- anObject asString ]
	 	 ifFalse: [ contents <- contents , (anObject asString) ].
    mode == 1 or: [ Character nl == anObject ]
	 ifTrue: [ self flush: stream buffer: contents. contents <- nil ].
    ^ anObject
! !

!CharStream methodsFor: 'misc'!

setBuffered
	mode <- 0.
!

setUnbuffered
	mode <- 1.
! !

!CharStream methodsFor: 'testing'!

atEnd
     position > endPtr ifTrue: [
	 contents <- self fill: stream mode: mode.
	 position <- 1.
	 endPtr <- contents size. ].
    ^ false
!

isEmpty
    ^false
! !


!CharStream methodsFor: 'private'!

fill: aStream mode: aMode
	<primitive 101>
	^ self primitiveFailed
!

flush: aStream buffer: aBuffer
	<primitive 102>
	^ self primitiveFailed
!

stream: aInteger
	stream <- aInteger.
	mode <- 0.
	position <- 1.
	endPtr <- 0.
! !

!CharStream class methodsFor: 'initialize'!

initialize
    " Define built in streams "
       Smalltalk at: #stdin ifAbsent: 
		[ Smalltalk at: #stdin put: (CharStream on: 0)].
       Smalltalk at: #stdout ifAbsent: 
       		[ Smalltalk at: #stdout put: (CharStream on: 1)].
       Smalltalk at: #stderr ifAbsent: 
       		[ Smalltalk at: #stderr put: (CharStream on: 2; setUnbuffered)].
! !

CharStream initialize !

ReadWriteStream subclass: 'FileStream'
                instanceVariableNames: 'file buffer'
                classVariableNames: '' poolDictionaries: '' category: nil!

!FileStream class methodsFor: 'basic'!

open: fileName mode: fileMode
    ^self new open: fileName mode: fileMode 
          ifFail: [ ^self error: 'Failed to open ''', fileName, '''' ]
!

open: fileName mode: fileMode ifFail: aBlock
    ^self new open: fileName mode: fileMode ifFail: aBlock
!

fileIn: aFileName
    | fileStream |
    fileStream <- self open: aFileName mode: 'r'.
    fileStream fileIn.
    fileStream close.
! !

!FileStream methodsFor: 'basic' !

open: fileName mode: fileMode ifFail: aBlock
    file <- File open: fileName mode: fileMode ifFail: aBlock.
    buffer <- nil.
    position <- file position.
!

openOnFile: aFile
    file <- aFile.
    buffer <- nil.
    position <- file position.
!

copy
    | newStream |
    newStream <- FileStream new.
    newStream openOnFile: file.
    ^ newStream
!

close
    file close.
    buffer <- nil
!

next
    | ch |
    buffer isNil ifTrue: [ ^ file next ]
                ifFalse: [ ch <- buffer. buffer <- nil. ^ ch ]
!

nextPut: aChar
    file nextPut: aChar.
!

peek
    buffer isNil ifTrue: [ buffer <- file next ].
    ^buffer
!

position: aInteger
    buffer <- nil.
    file position: aInteger.
    ^ aInteger
! 

position
    ^ buffer isNil ifTrue: [ file position ]
	          ifFalse: [ file position - 1]
!

contents
    ^self next: self size
!

size
    "Return the current size of the file, in bytes"
    ^file size

! !

!FileStream methodsFor: 'overriding inherited methods'!

reset
    self position: 0
!

setToEnd
    ^ self position: self size
!

skip: anInteger
    | pos |
    pos <- ((file position + anInteger) max: 0) min: self size - 1.
    file position: pos
!

reverseContents
    ^(ReadStream on: self contents) reverseContents
!

isEmpty
    ^self size == 0
! !

!FileStream methodsFor: 'testing'!

atEnd
    ^file atEnd

! !

!FileStream class methodsFor: 'Initialize'!

initialize
	| array n |
        Smalltalk at: #sourceFiles ifAbsent: [ 
	    n <- initSourceFile at: 1.
	    array <- Array new: 4.
	    array at: 1 put: (FileStream open: n mode: 'r').
	    array at: 2 put: (FileStream open: (n , 'c') mode: 'a').
	    Smalltalk at: #sourceFiles put: array
	]
! !

FileStream initialize !

!Stream methodsFor: 'reading chunks' !

nextChunk
    " Return the next chunk off the stream. "
    | chunk char |
    chunk <- WriteStream on: (String new: 0).
    [ self atEnd ] whileFalse: [
	char <- self next.
	char == $!! and: [ (self peekFor: $!!) not ] ifTrue: [ 
		char <- self next.	" Grab next character "
    		" Eat all newline and carage returns before chunk "
		[ (Character nl == char) or: [ Character cr == char ] ]
		     whileTrue:
			 [ self next. char <- self peek ].
	        ^ chunk contents ].
	chunk nextPut: char.
    ].
    ^ chunk contents
! !

!Stream methodsFor: 'writing chunks' !

nextChunkPut: aString
     " Put a string onto a stream as a chunk. "
     | char position |
     self space.
     1 to: aString size do: [ :i |
	char <- aString at: i.
	char == $!! ifTrue: [ self nextPut: char ].
	self nextPut: char.
     ].
     self nextPut: $!!.
! !


