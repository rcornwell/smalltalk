" Methods for Class stream and all it's subclasses"

" $Id: $ "

"
 $Log: $
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

ReadWriteStream subclass: 'FileStream'
                instanceVariableNames: 'file buffer'
                classVariableNames: '' poolDictionaries: '' category: nil!

!FileStream class methodsFor: 'basic'!

open: fileName mode: fileMode
    ^self open: fileName mode: fileMode 
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

!FileStream methodsFor: 'basic'!

open: fileName mode: fileMode ifFail: aBlock
    file <- File open: fileName mode: fileMode ifFail: aBlock.
    buffer <- nil
!

close
    file close.
    buffer <- nil
!

next
    | ch |
    buffer isNil ifTrue: [ ^file next ]
	         ifFalse: [ ch <- buffer. buffer <- nil. ^ ch ]
!

nextPut: aChar
    file nextPut: aChar
!

peek
    buffer
        isNil ifTrue: [ buffer <- self next ].
    ^buffer
!

position: position
    buffer <- nil.
    file position: position
! 

position
    buffer isNil ifTrue: [ ^file position ]
	         ifFalse: [ ^(file position) - 1]
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
    self position: self size
!

skip: anInteger
    | pos |
    pos <- ((self position + anInteger) max: 0) min: self size - 1.
    self position: pos
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

