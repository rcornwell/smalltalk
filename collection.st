

" $Id: collection.st,v 1.4 2001/02/04 02:43:10 rich Exp rich $ "

"
 $Log: collection.st,v $
 Revision 1.4  2001/02/04 02:43:10  rich
 Code Cleanup

 Revision 1.3  2000/08/26 20:23:50  rich
 Fixed some typos.
 Work around cascade problem.

 Revision 1.2  2000/02/01 18:09:47  rich
 Fixed a few misc errors.

 Revision 1.1  1999/09/02 15:57:59  rich
 Initial revision

"

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

! Association methodsFor: 'printing' !

printOn: aStream
    key printOn: aStream.
    aStream nextPutAll: '->'.
    value printOn: aStream
! !

! Association methodsFor: 'storing' !

storeOn: aStream
    aStream nextPutAll: '(Association key: '.
    self key storeOn: aStream.
    aStream nextPutAll: ' value: '.
    self value storeOn: aStream.
    aStream nextPut: $)
! !

Object variableSubclass: 'Collection' instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: ''!

Collection comment: 
 'I am a abstract class. I represent collections of objects.'!

! Collection class methodsFor: 'instance creation'!

with: anObject
    | newCollection |
    newCollection <- self new.
    newCollection add: anObject.
    ^ newCollection
!

with: firstObject with: secondObject
    | newCollection |
    newCollection <- self new.
    newCollection add: firstObject.
    newCollection add: secondObject.
    ^ newCollection
!

with: firstObject with: secondObject with: thirdObject
    | newCollection |
    newCollection <- self new.
    newCollection add: firstObject.
    newCollection add: secondObject.
    newCollection add: thirdObject.
    ^ newCollection
!

with: firstObject with: secondObject with: thirdObject with: fourthObject
    | newCollection |
    newCollection <- self new.
    newCollection add: firstObject.
    newCollection add: secondObject.
    newCollection add: thirdObject.
    newCollection add: fourthObject.
    ^ newCollection
! !

! Collection methodsFor: 'adding'!

add: newObject
    self subclassResponsibility
!

addAll: aCollection
    aCollection do: [ :element | self add: element ].
    ^aCollection
! !


! Collection methodsFor: 'removing'!

remove: oldObject ifAbsent: anExceptionBlock
    self subclassResponsibility
!

remove: oldObject
    self remove: oldObject
         ifAbsent: [ ^self error: 'Failed to remove object' ].
    ^oldObject
!

removeAll: aCollection
    aCollection do: [ :element | self remove: element ].
    ^aCollection
! !

! Collection methodsFor: 'testing'!

isEmpty
    ^self size == 0
!

includes: anObject
    self do: [ :element | anObject = element ifTrue: [ ^true ]].
    ^false
!

occurrencesOf: anObject
    | tally |
    tally <- 0.
    self do: [ :element | anObject = element ifTrue: [ tally <- tally + 1]].
    ^tally
! !

! Collection methodsFor: 'private'!

errorNotFound
    self error: 'Object is not in the collection'
!

maxPrint
    ^5000
! !

! Collection methodsFor: 'accessing'!

size
    | tally |
    tally <- 0.
    self do: [ :element | tally <- tally + 1].
    ^tally
! !


! Collection methodsFor: 'enumerating'!

do: aBlock
    self subclassResponsibility
!

collect: aBlock
    | newCollection |
    newCollection <- self species new.
    self do: [ :each | newCollection add: (aBlock value: each) ].
    ^newCollection
!

detect: aBlock
    ^self detect: aBlock ifNone: [ self errorNotFound ]
!

detect: aBlock ifNone: exceptionBlock
    self do: [ :each | (aBlock value: each) ifTrue: [ ^each ] ].
    ^exceptionBlock value    
!

inject: thisValue into: binaryBlock
    | nextValue |
    nextValue <- thisValue.
    self do: [ :each | nextValue <- binaryBlock value: nextValue value: each ].
    ^nextValue
!

reject: aBlock
    ^self select: [ :element | (aBlock value: element) == false ]
!

select: aBlock
    | newCollection |
    newCollection <- self species new.
    self do: [ :each | (aBlock value: each) ifTrue: [ newCollection add: each]].
    ^newCollection
! !

Collection variableSubclass: 'SequenceableCollection' instanceVariableNames: ''
           classVariableNames: '' poolDictionaries: '' category: nil!

SequenceableCollection comment: 
'My instances represent collections of objects that are ordered.  I provide
some access and manipulation methods.' !


! SequenceableCollection methodsFor: 'basic'!

atAll: aCollection put: anObject
    aCollection do: [ :index | self at: index put: anObject ]
!

atAllPut: anObject
    1 to: self size do: [ :index | self at: index put: anObject ]
!

first
    ^self at: 1
!

last
    self size < 1 ifTrue: [ ^self error: 'last not defined with no elements' ].
    ^self at: self size
!

indexOf: anElement ifAbsent: exceptionBlock
    1 to: self size do: [ :index | (self at: index) = anElement
                                     ifTrue: [ ^index ] ].
    ^exceptionBlock value
!

indexOf: anElement
    ^self indexOf: anElement ifAbsent: [ ^0 ]
!

= aCollection
    | size |
    self == aCollection ifTrue: [ ^true ].
    self species == aCollection species ifFalse: [ ^false ].
    (size <- self size) == aCollection size ifFalse: [ ^false ].
    1 to: size do:
        [ :i | (self at: i) = (aCollection at: i)
                   ifFalse: [ ^false ]. ].
    ^true
!

hash
    | hashValue |
    hashValue <- 0.
    self do: [ :element | hashValue <- ((hashValue bitShift: 1)
                                        bitXor:  element hash)
                                        bitAnd: 16r1FFFFFFF ].
    ^hashValue
! !

! SequenceableCollection methodsFor: 'private'!

matchSubCollection: aSubCollection startingAt: anIndex
    2 to: aSubCollection size do:
        [ :index | (self at: anIndex + index - 1) ~= (aSubCollection at: index)
                       ifTrue: [ ^false ]
        ].
    ^true
!

indexOfSubCollection: aSubCollection startingAt: anIndex
    ifAbsent: exceptionBlock
    | selfSize subSize |
    subSize  <- aSubCollection size.
    selfSize <- self size.
    anIndex + subSize - 1 <= selfSize ifTrue:
        [ anIndex to: selfSize - subSize + 1 do:
              [:index | (self at: index) = (aSubCollection at: 1)
                            ifTrue: [(self matchSubCollection: aSubCollection
                                           startingAt: index)
                                         ifTrue: [^index]
                                         ]
                            ]
              ].
    ^exceptionBlock value
!

indexOfSubCollection: aSubCollection startingAt: anIndex
    ^self indexOfSubCollection: aSubCollection startingAt: anIndex
        ifAbsent: [ ^0 ]
!

replaceFrom: start to: stop with: replacementCollection startingAt: repStart
    (self == replacementCollection and: [ repStart ~= 1 ])
        ifTrue: [ ^self error: 'replaceFrom:to:with:startingAt: called for 
in-place replacement, but starting index was not 1' ].
    "speed this up by making it zero based, otherwise we have to subtract
     1 from each use of index, and add one to the range"
    0 to: stop - start  do:
        [ :index |
          self at: (start + index)
               put: (replacementCollection at: (repStart + index)) ]
!

replaceFrom: start to: stop with: replacementCollection
    (stop - start + 1) ~= replacementCollection size
        ifTrue: [ ^self error: 'replacement range does not equal size of
replacement collection' ].
    self replaceFrom: start to: stop with: replacementCollection startingAt: 1
! !

! SequenceableCollection methodsFor: 'copying'!

, aSequenceableCollection
    | newCollection |
    newCollection <- self species new: (self size + aSequenceableCollection size)
.
    newCollection replaceFrom: 1 to: self size with: self.
    newCollection replaceFrom: (self size) + 1
                  to: self size + aSequenceableCollection size
                  with: aSequenceableCollection.
    ^newCollection
!

copyFrom: start to: stop
    | newCollection len |
    len <- stop - start + 1.
    newCollection <- self species new: len.
    newCollection replaceFrom: 1 to: len with: self startingAt: start.
    ^newCollection
!

copyReplaceAll: oldSubCollection with: newSubCollection
    | numOld newCollection sizeDifference newSubSize oldSubSize
      newStart oldStart copySize index |
    numOld <- self countSubCollectionOccurrencesOf: oldSubCollection.
    newSubSize <- newSubCollection size.
    sizeDifference <- newSubSize - oldSubCollection size + 1.
    newCollection <- self species new: (self size - (sizeDifference * numOld)).
    oldStart <- newStart <- 1.
    [ index <- self indexOfSubCollection: oldSubCollection
                   startingAt: oldStart.
      index > 0 ] whileTrue:
        [ copySize <- index - oldStart + 1.
          newCollection replaceFrom: newStart
                        to: newStart + copySize - 1
                        with: self
                        startingAt: oldStart.
          newStart <- newStart + copySize - 1.
          newCollection replaceFrom: newStart
                        to: newStart + newSubSize - 1
                        with newSubCollection.
          oldStart <- oldStart + copySize.
          newStart <- newStart + newSubSize ].
    "Copy the remaining part of self onto the tail of the new collection."
    newCollection replaceFrom: newStart
                 to: newCollection size
                 with: self
                 startingAt: oldStart.
    ^newCollection
!

copyReplaceFrom: start to: stop with: replacementCollection
    | newCollection newSize repSize |
    "### check for bounds "
    repSize <- replacementCollection size.
    newSize <- self size + repSize - (stop - start + 1).
    newCollection <- self species new: newSize.
    newCollection replaceFrom: 1 to: start - 1 with: self startingAt: 1.
    newCollection replaceFrom: start
                  to: start + repSize - 1
                  with: replacementCollection.
    newCollection replaceFrom: start + repSize
                  to: newCollection size
                  with: self
                  startingAt: stop + 1.
    ^newCollection
!

copyWith: newElement
    | newCollection len |
    len <- self size + 1.
    newCollection <- self species new: len.
    newCollection replaceFrom: 1 to: self size with: self.
    newCollection at: len put: newElement.
    ^newCollection
!

copyWithout: oldElement
    | newCollection numOccurrences i |
    numOccurrences <- 0.
    self do:
        [ :element |
          element = oldElement
            ifTrue: [ numOccurrences <- numOccurrences + 1 ] ].
    newCollection <- self species new: (self size - numOccurrences).
    i <- 1.
    self do:
        [ :element |
          element ~= oldElement
            ifTrue: [ newCollection at: i put: element.
                      i <- i + 1 ]
        ].
    ^newCollection
! !

! SequenceableCollection methodsFor: 'enumerating'!

do: aBlock
    "Evaluate aBlock for all elements in the sequenceable collection"
    1 to: self size do:
        [ :i | aBlock value: (self at: i) ]
!

findFirst: aBlock
    "Returns the index of the first element of the sequenceable collection
    for which aBlock returns true"
    1 to: self size do:
        [ :i | (aBlock value: (self at: i))
                 ifTrue: [ ^i ] ].
    ^0
!

findLast: aBlock
    self size to: 1 by: -1 do:
        [ :i | (aBlock value: (self at: i))
                 ifTrue: [ ^i ] ].
    ^0
!

reverseDo: aBlock
    self size to: 1 by: -1 do:
        [ :i | aBlock value: (self at: i) ]
!

with: aSequenceableCollection do: aBlock
    self size = aSequenceableCollection size
        ifFalse:
            [ ^self error: 'sequenceable collections must have same size' ].
    1 to: self size do:
        [ :i | aBlock value: (self at: i)
                      value: (aSequenceableCollection at: i) ]
! !

! SequenceableCollection methodsFor: 'private'!

countSubCollectionOccurrencesOf: aSubCollection
    | colIndex subColIndex count |
    colIndex <- 1.
    count <- 0.
    [ subColIndex <- self indexOfSubCollection: aSubCollection
                         startingAt: colIndex.
      subColIndex > 0 ] whileTrue:
        [ count <- count + 1.
          colIndex <- colIndex + aSubCollection size ].
    ^count
!

grow
    | newCollection |
    newCollection <- self species new: self basicSize + self growSize.
    newCollection replaceFrom: 1 to: self size with: self.
    ^self become: newCollection
!
    
growSize
    ^32

! !

SequenceableCollection subclass: 'Interval'
                       instanceVariableNames: 'start stop step'
                       classVariableNames: ''
                       poolDictionaries: ''
                       category: nil!

Interval comment: 
'My instances represent ranges of objects.' !

! Interval class methodsFor: 'instance creation'!

from: startInteger to: stopInteger by: stepInteger
    ^self new initializeFrom: startInteger to: stopInteger by: stepInteger
!

from: startInteger to: stopInteger    
    ^self from: startInteger to: stopInteger by: 1

! !

! Interval methodsFor: 'basic'!

do: aBlock
    | i |
    i <- start.
    step > 0
        ifTrue: [
            [ i <= stop ] whileTrue:
                [ aBlock value: i.
                  i <- i + step ]
        ]
        ifFalse: [
            [ i >= stop ] whileTrue:
                [ aBlock value: i.
                  i <- i + step ]
        ]
!

collect: aBlock
    | i result j |
    result <- self species new: self size.
    i <- 1.
    j <- start.
    step > 0
        ifTrue: [
            [ j <= stop ]
                whileTrue:
                    [ result at: i put: (aBlock value: j).
                        j <- j + step.
                        i <- i + 1 ]
        ]
        ifFalse: [
            [ j >= stop ]
                whileTrue:
                    [ result at: i put: (aBlock value: j).
                      j <- j + step.
                      i <- i + 1 ]
        ]
!    

size
    step > 0
        ifTrue: [
            stop >= start ifTrue: [ ^(stop - start) // step + 1 ]
                          ifFalse: [ ^0 ]
        ]
        ifFalse: [
            start >= stop ifTrue: [ ^(start - stop) // step + 1 ]
                          ifFalse: [ ^0 ]
        ]
!

species
    ^Array
!


at: index
    (index >= 1 and: [index <= self size])
        ifTrue: [ ^start + (step * (index - 1)) ]
        ifFalse: [ self error: 'subscript out of bounds' ]
!

at: index put: anObject
    self error: 'you cannot store into an Interval'
!

add: newObject
    self error: 'elements cannot be added to an Interval'
!

remove: newObject
    self error: 'elements canot be removed from an Interval'
! !

! Interval methodsFor: 'testing'!

= anInterval
    ^(start = anInterval start) &
        (stop = anInterval stop) &
        (step = anInterval step)
!

hash
    ^(start bitXor: stop) bitXor: step
! !


! Interval methodsFor: 'printing'!

printOn: aStream
    aStream nextPutAll: self classNameString.
    aStream nextPut: Character space.
    start printOn: aStream.
    aStream nextPut: $,.
    stop printOn: aStream.
    aStream nextPut: $,.
    step printOn: aStream
! !

! Interval methodsFor: 'storing'!

storeOn: aStream
    aStream nextPut: $(.
    aStream nextPutAll: self classNameString.
    aStream nextPutAll: ' from: '.
    start storeOn: aStream.
    aStream nextPutAll: ' to: '.
    stop storeOn: aStream.
    aStream nextPutAll: ' by: '.
    step storeOn: aStream.
    aStream nextPut: $)
! !

! Interval methodsFor: 'private methods'!

initializeFrom: startInteger to: stopInteger by: stepInteger
    start <- startInteger.
    stop <- stopInteger.
    step <- stepInteger
!

start
    ^start
!

stop
    ^stop
!

step
    ^step
! !

SequenceableCollection variableSubclass: 'ArrayedCollection'
                       instanceVariableNames: '' classVariableNames: ''
                       poolDictionaries: '' category: nil!

ArrayedCollection comment: 
'My instances are objects that are generally fixed size, and are accessed
by an integer index.  The ordering of my instance''s elements is determined 
externally; I will not rearrange the order of the elements.' !

! ArrayedCollection class methodsFor: 'instance creation'!

with: element1
    | anArrayedCollection |
    anArrayedCollection <- self new: 1.
    anArrayedCollection at: 1 put: element1.
    ^anArrayedCollection
!

with: element1 with: element2
    | anArrayedCollection |
    anArrayedCollection <- self new: 2.
    anArrayedCollection at: 1 put: element1.
    anArrayedCollection at: 2 put: element2.
    ^anArrayedCollection
!

with: element1 with: element2 with: element3
    | anArrayedCollection |
    anArrayedCollection <- self new: 3.
    anArrayedCollection at: 1 put: element1.
    anArrayedCollection at: 2 put: element2.
    anArrayedCollection at: 3 put: element3.
    ^anArrayedCollection
!

with: element1 with: element2 with: element3 with: element4
    | anArrayedCollection |
    anArrayedCollection <- self new: 4.
    anArrayedCollection at: 1 put: element1.
    anArrayedCollection at: 2 put: element2.
    anArrayedCollection at: 3 put: element3.
    anArrayedCollection at: 4 put: element4.
    ^anArrayedCollection
! !

! ArrayedCollection methodsFor: 'basic'!

size
    <primitive 47>
    " Just Call basic size. "
!

add: value
    self shouldNotImplement
! !


Array superclass: ArrayedCollection.
Array class superclass: (ArrayedCollection class).
ArrayedCollection addSubclass: Array!

Array comment: 
'My instances are objects that have array-like properties: they are directly 
indexable by integers starting at 1, and they are fixed in size.  I inherit
object creation behavior messages such as #with:, as well as iteration
and general access behavior from SequenceableCollection.' !

! Array methodsFor: 'printing'!

printOn: aStream
    aStream nextPut: $(.
    self do:
        [ :elt | elt printOn: aStream.
                 aStream space ].
    aStream nextPut: $)
! !


! Array methodsFor: 'storing'!

storeOn: aStream
    | index |
    aStream nextPutAll: '(('.
    aStream nextPutAll: self classNameString.
    aStream nextPutAll: ' basicNew: '.
    aStream print: self basicSize.
    aStream nextPut: $).
    index <- 1.
    self do:
        [ :element | aStream nextPutAll: ' at: '.
                     aStream print: index.
                     aStream nextPutAll: ' put: '.
                     aStream store: element. 
                     aStream nextPut: $;.
                     index <- index + 1 ].
    index > 1 ifTrue: [ aStream nextPutAll: ' yourself' ].
    aStream nextPut: $)
! !

ArrayedCollection variableByteSubclass: 'ByteArray' instanceVariableNames: ''
                  classVariableNames: '' poolDictionaries: '' category: nil!

ByteArray comment: 
'My instances are similar to strings in that they are both represented as
a sequence of bytes, but my individual elements are integers, where as
a String''s elements are characters.' !

! ByteArray methodsFor: 'copying'!

shallowCopy
    | newArray |
    newArray <- self species new: self size.
    newArray replaceFrom: 1 to: self size with: self.
    ^newArray
!

deepCopy
    ^self shallowCopy

! !


! ByteArray methodsFor: 'converting'!

asString
    | string size |
    size <- self size.
    string <- String new: size.
    string replaceFrom: 1 to: size withByteArray: self startingAt: 1.
    ^string
! !

! ByteArray methodsFor: 'private'!

growSize
    ^40
! !

ArrayedCollection variableWordSubclass: 'WordArray'
		  instanceVariableNames: ''
                  classVariableNames: ''
		  poolDictionaries: ''
		  category: nil!

WordArray comment: 
'My instances are arrays of words.' !

! WordArray methodsFor: 'copying'!

shallowCopy
    | newArray |
    newArray <- self species new: self size.
    newArray replaceFrom: 1 to: self size with: self.
    ^newArray
!

deepCopy
    ^self shallowCopy

! !

! WordArray methodsFor: 'private'!

growSize
    ^40
! !

SequenceableCollection subclass: 'LinkedList'
                       instanceVariableNames: 'firstLink lastLink'
                       classVariableNames: ''
                       poolDictionaries: ''
                       category: nil !

LinkedList comment: 'I provide methods that access and manipulate linked lists.' !

! LinkedList methodsFor: 'accessing'!

at: index
    "Return the element that is index into the linked list."
    | i element |
    i <- 1.
    element <- firstLink.
    [element isNil] whileFalse:
        [ i = index ifTrue: [ ^element ].
          i <- i + 1.
          element <- element nextLink ].
    ^self error: 'index out of bounds in linked list'
!

at: index put: object
    self error: 'Do not store into a LinkedList using at:put:'
! !

! LinkedList methodsFor: 'adding'!

add: aLink
    "Add aLink at the end of the list; return aLink."
    self addLast: aLink.
    ^aLink
!

addFirst: aLink
    "Add aLink at the head of the list; return aLink."
    lastLink isNil ifTrue: [ lastLink <- aLink ].
    aLink nextLink: firstLink.
    firstLink <- aLink.
    ^aLink
!

addLast: aLink
    "Add aLink at then end of the list; return aLink."
    firstLink isNil ifTrue: [ firstLink <- aLink ].
    lastLink notNil ifTrue: [ lastLink nextLink: aLink ].
    lastLink <- aLink.
    ^aLink
!

removeFirst
    "Remove the first element from the list and return it, or error if the
    list is empty."

    ^self remove: firstLink
          ifAbsent: [ ^self error: 'attempted to remove from an empty list' ]
!    

removeLast
    "Remove the final element from the list and return it, or error if the
    list is empty."

    ^self remove: lastLink
          ifAbsent: [ ^self error: 'attempted to remove from an empty list' ]
!

remove: aLink ifAbsent: aBlock
    "Remove aLink from the list and return it, or invoke aBlock if it's not
    found in the list."
    | temp |
    aLink == firstLink
        ifTrue: [ firstLink <- firstLink nextLink.
                  firstLink isNil ifTrue: [ lastLink <- nil ] ]
        ifFalse: [ temp <- firstLink.
                   [ temp isNil ifTrue: [ ^aBlock value ].
                     temp nextLink == aLink ] whileFalse:
                        [ temp <- temp nextLink ].
                   temp nextLink: aLink nextLink.
                   aLink == lastLink ifTrue: [ lastLink <- temp ] ].
    aLink nextLink: nil.
    ^aLink
! !

! LinkedList methodsFor: 'enumerating'!

do: aBlock
    | aLink |
    aLink <- firstLink.
    [ aLink notNil] whileTrue:
        [ aBlock value: aLink.
          aLink <- aLink nextLink]
! !

! LinkedList methodsFor: 'testing'!

isEmpty
    "Returns true if the list contains no members"
    ^firstLink isNil
! !


SequenceableCollection variableSubclass: 'OrderedCollection'
                       instanceVariableNames: 'firstIndex lastIndex'
                       classVariableNames: ''
                       poolDictionaries: ''
                       category: nil
!

OrderedCollection comment: 
'My instances represent ordered collections of arbitrary typed objects which
are not directly accessible by an index.  They can be accessed indirectly
through an index, and can be manipulated by adding to the end or based
on content (such as add:after:)' !

! OrderedCollection class methodsFor: 'instance creation'!

new: anInteger
    ^(super new: anInteger) initIndices
!

new
    ^self new: 16

! !

! OrderedCollection methodsFor: 'accessing'!

at: index
    | location |
    location <- index + firstIndex - 1.
    (location >= firstIndex and: [ location <= lastIndex ])
        ifTrue: [ ^self basicAt: location ]
        ifFalse: [ self error: 'index out of bounds for ordered collection' ]
!

at: index put: anObject
    | location |
    location <- index + firstIndex - 1.
    (location >= firstIndex and: [ location <= lastIndex ])
        ifTrue: [ ^self basicAt: location put: anObject ]
        ifFalse: [ self error: 'index out of bounds for ordered collection' ]
!    

after: oldObject
    "Return the element after oldObject.  Error if oldObject not found or
    if no following object is available"
    firstIndex to: lastIndex do:
        [ :index |              "should we use '=' or '==' here?"
            (self basicAt: index) = oldObject
                ifTrue: [
                    index < lastIndex
                        ifTrue: [ ^self basicAt: index + 1 ]
                        ifFalse: [ ^self error: 'no following object' ] ]
        ].
    self error: 'object not found'
!

before: oldObject
    "Return the element after oldObject.  Error if oldObject not found or
    if no following object is available"
    firstIndex to: lastIndex do:
        [ :index |              "should we use '=' or '==' here?"
            (self basicAt: index) = oldObject
                ifTrue: [
                    index > firstIndex
                        ifTrue: [ ^self basicAt: index - 1 ]
                        ifFalse: [ ^self error: 'no preceding object' ] ]
        ].
    self error: 'object not found'
!

copyEmpty
    ^self species new: self basicSize
!

size
    ^lastIndex - firstIndex + 1
! !


! OrderedCollection methodsFor: 'adding'!

add: anObject
    ^self addLast: anObject
!

add: newObject after: oldObject
    firstIndex to: lastIndex do:
        [ :i | (self basicAt: i) = oldObject
                 ifTrue: [ self at: i + 1 insertObject: newObject.
                           ^newObject ] ].
    self error: 'object not found in collection'
!

add: newObject before: oldObject
    firstIndex to: lastIndex do:
        [ :i | (self basicAt: i) = oldObject
                 ifTrue: [ self at: i - 1 insertObject: newObject.
                           ^newObject ] ].
    self error: 'object not found in collection'
!


addAllFirst: anOrderedCollection
    anOrderedCollection reverseDo:
        [ :element | self addFirst: element ].
    ^anOrderedCollection
!
    
addAllLast: anOrderedCollection
    anOrderedCollection do:
        [ :element | self addLast: element ].
    ^anOrderedCollection
!
    

addFirst: newObject
    firstIndex = 1
        ifTrue: [ self growFirst ].
    firstIndex <- firstIndex - 1.
    ^self basicAt: firstIndex put: newObject
!
    
addLast: newObject
    lastIndex = self basicSize
        ifTrue: [ self growLast ].
    lastIndex <- lastIndex + 1.
    ^self basicAt: lastIndex put: newObject
! !

! OrderedCollection methodsFor: 'removing'!

removeFirst
    lastIndex < firstIndex
        ifTrue: 
            [ ^self error: 'attempted to remove from an empty collection' ].
    firstIndex <- firstIndex + 1.
    ^self basicAt: firstIndex - 1
!

removeLast
    lastIndex < firstIndex
        ifTrue: 
            [ ^self error: 'attempted to remove from an empty collection' ].
    lastIndex <- lastIndex - 1.
    ^self basicAt: lastIndex + 1
! !

! OrderedCollection methodsFor: 'private methods'!

initIndices
    firstIndex <- self basicSize // 2 max: 1.
    lastIndex <- firstIndex - 1
!

firstIndex: first lastIndex: last
    firstIndex <- first.
    lastIndex <- last
!

growFirst
    "Make growSize room at the start of the ordered collection, and copy
    all the elements of the old collection into the new one starting
    at the value that growSize returned."
    | newOrderedCollection delta |
    delta <- self growSize.
    newOrderedCollection <- self growTo: self basicSize + delta.
    firstIndex to: lastIndex do:
        [ :index | newOrderedCollection basicAt: delta + index - 1
                                        put: (self basicAt: index) ].
    newOrderedCollection firstIndex: delta + firstIndex - 1
                         lastIndex: delta + lastIndex - 1.
    ^self become: newOrderedCollection    
!

growLast
    "Make growSize room at the end of the ordered collection, and copy
    all the elements of the old collection into the new one starting
    at firstIndex."
    | newOrderedCollection |
    newOrderedCollection <- self growTo: self basicSize + self growSize.
    firstIndex to: lastIndex do:
        [ :index | newOrderedCollection basicAt: index
                                        put: (self basicAt: index) ].
    newOrderedCollection firstIndex: firstIndex
                         lastIndex: lastIndex.
    ^self become: newOrderedCollection    
!

grow
    "Make growSize room in the collection, putting the old contents in the
    middle."
    | oldSize newSize newFirstIndex newOrderedCollection |
    oldSize <- self basicSize.
    newSize <- oldSize + self growSize.
    newOrderedCollection <- self growTo: newSize.
    newFirstIndex <- newSize - oldSize // 2 max: 1.
    1 to: self size do:
        [ :i | newOrderedCollection basicAt: i + newFirstIndex - 1
                                    put: (self basicAt: i + firstIndex - 1) ].
    newOrderedCollection firstIndex: newFirstIndex
                         lastIndex: newFirstIndex + self size - 1.
    ^self become: newOrderedCollection
!

growTo: anInteger
    ^self species new: anInteger
!    

growSize
    ^10                         "number out of a hat"
!

at: index insertObject: anObject
    lastIndex = self basicSize ifTrue: [ self growLast ].
    lastIndex to: index by: -1 do:
        [ :i | self basicAt: i + 1
                    put: (self basicAt: i) ].
    self basicAt: index put: anObject.
    ^anObject
! !

OrderedCollection variableSubclass: 'SortedCollection'
                  instanceVariableNames: 'sortBlock'
                  classVariableNames: '' poolDictionaries: '' category: nil!

SortedCollection comment:
'I am a collection of objects, stored and accessed according to some
sorting criteria.  I store things using a bubble sort.  My instances have a
comparison block associated with them; this block takes two arguments and
is a predicate which returns true if the first argument should be sorted
earlier than the second.  The default block is [ :a :b | a <= b ], but I
will accept any block that conforms to the above criteria.' !

! SortedCollection class methodsFor: 'instance creation'!

new
    ^self sortBlock: [ :a :b | a <= b ]
!

sortBlock: aSortBlock
    ^super new setSortBlock: aSortBlock

! !

! SortedCollection methodsFor: 'basic'!

addFirst: anObject
    self shouldNotImplement
!

addLast: anObject
    self shouldNotImplement
!

at: index put: anObject
    self shouldNotImplement
!

add: newObject after: oldObject
    self shouldNotImplement
!

add: newObject before: oldObject
    self shouldNotImplement
!

add: anObject
    "Add anObject into the collection at the proper place using bubble sort."
    super addFirst: anObject.
    firstIndex + 1 to: lastIndex do:
        [ :i | (sortBlock value: (self basicAt: i)
                          value: anObject)
                  ifTrue: [ self basicAt: i - 1 put: (self basicAt: i) ]
                  ifFalse: [ self basicAt: i - 1 put: anObject.
                             ^anObject ] ].
    self basicAt: lastIndex put: anObject.
    ^anObject
! !

! SortedCollection methodsFor: 'instance protocol'!

sortBlock
    ^sortBlock
!

sortBlock: aSortBlock
    "Change the sort criteria for a sorted collection, resort the elements of 
    the collection, and return it."
    | newSortedCollection |
    newSortedCollection <- SortedCollection sortBlock: aSortBlock.
    self do: [ :element | newSortedCollection add: element ].
    ^self become: newSortedCollection
! !

! SortedCollection methodsFor: 'copying'!

copyEmpty
    ^(super copyEmpty) setSortBlock: sortBlock
! !


! SortedCollection methodsFor: 'private methods'!

setSortBlock: aSortBlock
    sortBlock <- aSortBlock
!

growTo: anInteger
    | newCollection |
    newCollection <- super growTo: anInteger.
    newCollection setSortBlock: sortBlock.
    ^newCollection
! !

" Fix up class hierchy now that we have superclasses defined"
String superclass: ArrayedCollection.
String class superclass: (ArrayedCollection class).
ArrayedCollection addSubclass: String!

String comment: 
'My instances represent string data types.  I provide accessing and
manipulation methods for string data types.' !


! String methodsFor: 'Conversion'!

asSymbol
	<primitive 91>
! !

! String methodsFor: 'basic'!

size
    <primitive 47>
    ^self primitiveFailed
!

at: index
    <primitive 48>
    ^self primitiveFailed
!

basicAt: index
    <primitive 48>
    ^self primitiveFailed
!

at: index put: value
    <primitive 49>
    ^self primitiveFailed
!

basicAt: index put: value
    <primitive 49>
    ^self primitiveFailed
!

fromString: aString
    ^aString copyFrom: 1 to: aString size
!

readFrom: aStream
    | str newChar |
    str <- WriteStream on: (String new: 0).
    aStream do:                 " ### Is this risky, doing a next inside? "
        [ :char | char == $'
                      ifTrue: [ newChar <- aStream next.
                                newChar == $' ifFalse: [ str nextPut: $' ].
                                str nextPut: newChar ]
                      ifFalse: [ str nextPut: char ]
        ].
    ^str contents
! !

! String methodsFor: 'comparing'!

< aString
    "Return true if the receiver is less than aString, ignoring case
    differences."
    self >= aString ifTrue: [ ^false ]
                    ifFalse: [ ^true ]
!

> aString
    "Return true if the receiver is greater than aString, ignoring case
    differences."
    self <= aString ifTrue: [ ^false ]
                    ifFalse: [ ^true ]
!

<= aString
    "Returns true if the receiver is less than or equal to aString,
    ignoring case differences.  If is receiver is an initial substring of
    aString, it is considered to be less than aString."
    | c1 c2 |
    " Scan self and aString until a character is clearly greater or lesser
      (All preceding characters must have been equal).  If the end is reached,
      one of the strings is a possibly improper initial substring of the other,
      and for the receiver to be less than aString, it must be the initial
      substring."
    1 to: (self size min: aString size) do:
        [ :i | c1 <- (self at: i) asLowercase.
               c2 <- (aString at: i) asLowercase.
               c1 < c2 ifTrue: [ ^true ].
               c1 > c2 ifTrue: [ ^false ] ].
    ^self size <= aString size
!

>= aString
    "Returns true if the receiver is greater than or equal to aString,
    ignoring case differences.  If is aString is an initial substring of
    the receiver, it is considered to be less than the receiver."
    | c1 c2 |
    1 to: (self size min: aString size) do:
        [ :i | c1 <- (self at: i) asLowercase.
               c2 <- (aString at: i) asLowercase.
               c1 < c2 ifTrue: [ ^false ].
               c1 > c2 ifTrue: [ ^true ] ].
    ^self size >= aString size
!

sameAs: aString
    "Returns true if the receiver is the same string as aString, ignoring
    case differences."
    self size ~= aString size ifTrue: [ ^false ].
    1 to: self size do:
        [ :i | (self at: i) asLowercase ~= (aString at: i) asLowercase
                ifTrue: [ ^false ] ].
    ^true
!


match: aString
    ^self asLowercase matchSubstring: 1 in: aString asLowercase at: 1
! !


! String methodsFor: 'converting'!

asUppercase
    "Returns a copy of self as an uppercase string"
    | newStr |
    newStr <- self species new: self size.
    1 to: self size do:
        [ :i | newStr at: i put: (self at: i) asUppercase ].
    ^newStr
!

asLowercase
    "Returns a copy of self as a lowercase string"
    | newStr |
    newStr <- self species new: self size.
    1 to: self size do:
        [ :i | newStr at: i put: (self at: i) asLowercase ].
    ^newStr
!

asString
    ^self
!

asByteArray
    | byteArray size |
    size <- self size.
    byteArray <- ByteArray new: size.
    byteArray replaceFrom: 1 to: size withString: self startingAt: 1.
    ^byteArray
!

asInteger
    | result |
    result <- 0.
    self do: 
        [ :ch | ch isDigit
                    ifFalse: [ ^result ].
                result <- result * 10 + ch digitValue ].
    ^result
! !

! String methodsFor: 'copying'!

shallowCopy
    | newStr |
    newStr <- self species new: self size.
    1 to: self size do:
        [ :i | newStr at: i put: (self at: i) ].
    ^newStr
!

deepCopy
    ^self shallowCopy
!

, aString
    "Join aString onto end of string"
    | newString index len |
    " Make new string "
    len <- self size + aString size. 
    newString <- String new: len.
    index <- 1.
    " Copy first string to new location "
    1 to: self size do: [ :i | newString at: index put: (self at: i ).
			  index <- index + 1].
    " Now copy over second string "
    1 to: aString size do: [ :i | newString at: index put: (aString at: i ).
			  index <- index + 1].
    ^ newString
! !


! String methodsFor: 'printing'!

printOn: aStream
    self storeOn: aStream
! !

! String methodsFor: 'storing'!

storeOn: aStream
    aStream nextPut: $'.
    self do:
        [ :char | char == $' ifTrue: [ aStream nextPut: char ].
                  aStream nextPut: char ].
    aStream nextPut: $'
! !

! String methodsFor: 'private'!

matchSubstring: p in: aString at: s
    | pc |
    p > self size
        ifTrue: [ ^s > aString size ].
    pc <- self at: p.
    pc = $*
        ifTrue: [ s to: (aString size) + 1 do:
                    [ :ss | (self matchSubstring: p + 1
                                  in: aString
                                  at: ss)
                                ifTrue: [ ^true ] ].
                  ^false ].
    s > aString size ifTrue: [ ^false ].
    pc = $#
        ifTrue: [ ^self matchSubstring: p + 1 in: aString at: s + 1 ].

    pc = (aString at: s)
        ifTrue: [ ^self matchSubstring: p + 1 in: aString at: s + 1 ].
    ^false
! !

Symbol comment: 
'My instances are unique throughout the Smalltalk system.  My instances 
behave for the most part like strings, except that they print differently,
and I guarantee that any two instances that have the same printed 
representation are in fact the same instance.' !

! Symbol class methodsFor: 'instance creation'!

internCharacter: aCharacter
    | s |
    s <- String new: 1.
    s at: 1 put: aCharacter.
    ^s asSymbol.
! !

! Symbol methodsFor: 'accessing' !

asString
    ^value
! !

! Symbol methodsFor: 'converting'!

asSymbol
    ^self
! !

! Symbol methodsFor: 'misc'!

species
    ^String
! !

! Symbol methodsFor: 'printing'!

printOn: aStream
    aStream nextPutAll: (self asString)
! !

! Symbol methodsFor: 'storing'!

storeOn: aStream
    aStream nextPut: $#.
    aStream nextPutAll: (self asString)
! !

! Symbol methodsFor: 'primitives'!

flushCache
     " Flush the method cache of this selector. "
     <primitive 106>
! !


Collection subclass: 'Bag' instanceVariableNames: 'contents'
           classVariableNames: '' poolDictionaries: '' category: nil!

Bag comment:
'My instances are unordered collections of objects.  You can think
of me as a set with a memory; that is, if the same object is added to me
twice, then I will report that that element has been stored twice.'!

! Bag class methodsFor: 'basic'!

new
    ^super new setDictionary
! !

! Bag methodsFor: 'adding'!

add: newObject
    ^self add: newObject withOccurrences: 1.
!

add: newObject withOccurrences: anInteger
    contents at: newObject
             put: ((self occurrencesOf: newObject) + anInteger).
    ^newObject
! !

! Bag methodsFor: 'accessing'!

at: index
    self errorNotKeyed
!

at: index put: value
    self errorNotKeyed
!

size
    | tally |
    tally <- 0.
    contents do: [ :each | tally <- tally + each ].
    ^tally
!

includes: anObject
    ^contents includesKey: anObject 
!

occurrencesOf: anObject
    (self includes: anObject)
	ifTrue: [ ^contents at: anObject ]
	ifFalse: [ ^0 ]
! !

! Bag methodsFor: 'removing'!

remove: oldObject ifAbsent: anExceptionBlock
    | count |
    count <- self occurrencesOf: oldObject.
    count = 0 ifTrue: [ ^anExceptionBlock value ].
    count = 1 ifTrue: [ contents removeKey: oldObject ]
              ifFalse: [ contents at: oldObject put: count - 1 ].
    ^oldObject
! !

! Bag methodsFor: 'testing'!

hash
    ^contents hash
!

= aBag
    self class == aBag class
        ifFalse: [ ^false ].
    ^contents = aBag contents
! !

! Bag methodsFor: 'enumerating'!

do: aBlock
     contents associationsDo: 
         [ :assoc | assoc value timesRepeat: [ aBlock value: assoc key ]]
! !

! Bag methodsFor: 'storing'!

storeOn: aStream
    | noElements |
    aStream nextPut: $(.
    aStream nextPutAll: self classNameString.
    aStream nextPutAll: ' new'.
    noElements <- true.
    contents associationsDo:
      [ :assoc | aStream nextPutAll: ' add: '.
                 aStream store: assoc key.
                 aStream nextPutAll: ' withOccurrences: '.
                 aStream store: assoc value.
                 aStream nextPut: $;.
                 noElements <- false ].
    noElements ifFalse: [ aStream nextPutAll: '; yourself' ].
    aStream nextPut: $)
! !

! Bag methodsFor: 'private'!

setDictionary
    contents <- Dictionary new
!

errorNotKeyed
     self error: self class name, 's do not respond to keyed access messages'
!

contents
    ^contents
! !

"Fix up class hierchy now that we have superclasses defined"
Set superclass: Collection.
Set class superclass: (Collection class).
Collection addSubclass: Set!

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
		tally <- tally - 1 .
		self rehashAfterIndex: index
	].
	^ anObject
!

remove: anObject ifAbsent: aBlock
	| index |
	index <- self findIndexOrNil: anObject ifFull: [ nil ].
	index isNil ifTrue: [ ^ aBlock value ].
	tally <- tally - 1 .
	self rehashAfterIndex: index.
	^ anObject
!

size
	^ tally
! !

! Set methodsFor: 'testing' !

includes: anObject
	| index |
	index <- self findIndexOrNil: anObject ifAbsent: [ ^ nil ].
	index isNil ifTrue: [ ^ false ].
	^ (self basicAt: index) notNil
!

isEmpty
	^ tally == 0
!

occurrencesOf: anObject
	anObject isNil ifTrue: [ ^ 1 ].
	(self includes: anObject) ifTrue: [ ^ 1 ] ifFalse: [ ^ 0 ]
!

hash
    "Return the hash code for the members of the set.  Since order is
    unimportant; we use a commutative operator to compute the hash value."
    ^self inject: tally
          into: [ :hashValue :member | hashValue + member hash ]
!

= aSet
    "Returns true if the two sets have the same membership, false if not"
    self class == aSet class
        ifFalse: [ ^false ].
    tally = aSet size  ifFalse: [ ^false ].
    self do: [ :element | (aSet includes: element)
                            ifFalse: [ ^false ] ].
    ^true

! !

! Set methodsFor: 'Enumeration' !

do: aBlock
	"Call block for each non-nil element of set"
	| element |
	1 to: self basicSize do: [ :index |
	   element <- self basicAt: index.
	   element notNil ifTrue: [ aBlock value: element ]
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
		(key isNil or: [key = anObject]) ifTrue: [ ^ index ].
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
	^ self at: key ifAbsent: [ self errorKeyNotFound: key ]
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

associationAt: key
    ^self associationAt: key ifAbsent: [ ^self errorKeyNotFound: key ]
!

associationAt: key ifAbsent: aBlock
    | index assoc|
    index <- self findObjectIndex: key.
    assoc <- self basicAt: index.
    assoc isNil ifTrue: [ ^aBlock value ]
                ifFalse: [ ^assoc ]
!

keyAtValue: value ifAbsent: exceptionBlock
    self associationsDo:
        [ :assoc | value = assoc value
                     ifTrue: [ ^assoc key ] ].
    ^exceptionBlock value
!

keyAtValue: value
    ^self keyAtValue: value ifAbsent: []
!

keys
    | aSet |
    aSet <- Set new: tally.
    self keysDo: [ :aKey | aSet add: aKey ].
    ^aSet
!

values
    | aBag |
    aBag <- Bag new.
    self do: [ :aValue | aBag add: aValue ].
    ^aBag
! !

! Dictionary methodsFor: 'testing'!

includesAssociation: anAssociation
    | assoc |
    assoc <- self associationAt: anAssociation key ifAbsent: [ ^false ].
    ^assoc value = anAssociation value
!

includesKey: key
    self associationAt: key ifAbsent: [ ^false ].
    ^true
!

includes: anObject
    self do: [ :element | element = anObject ifTrue: [ ^true ] ].
    ^false
!

occurrencesOf: aValue
    | count |
    count <- 0.
    self do: [ :element | element = aValue
                            ifTrue: [ count <- count + 1] ].
    ^count
! !

! Dictionary methodsFor: 'removing'!

removeAssociation: anAssociation
    self removeKey: anAssociation key ifAbsent: [].
    ^anAssociation
!

removeKey: key
    ^self removeKey: key ifAbsent: [ ^self errorKeyNotFound: key ]
!

removeKey: key ifAbsent: aBlock
    | index assoc |
    index <- self findIndexOrNil: key ifFull: [ ^aBlock value ].
    assoc <- self basicAt: index. 
    self basicAt: index put: nil.
    tally <- tally - 1.
    self rehashAfterIndex: index.
    ^assoc value
!

remove: anObject
    self error: 'remove: not allowed in Dictionary'
!

remove: anObject ifAbsent: aBlock
    self error: 'remove:ifAbsent: not allowed in Dictionary'
! !

! Dictionary methodsFor: 'enumerating'!

associationsDo: aBlock
    super do: [ :assoc | aBlock value: assoc ]
!

"These could be implemented more efficiently by doing the super do
 directly, or doing the explicit scanning of the dictionary by hand"
keysDo: aBlock
    self associationsDo: [ :assoc | aBlock value: assoc key ]
!

do: aBlock
    self associationsDo: [ :assoc | aBlock value: assoc value ]
!

collect: aBlock
    | aBag |
    aBag <- Bag new.
    self do: [ :element | aBag add: (aBlock value: element) ].
    ^aBag
!

select: aBlock
    | newDict |
    newDict <- self species new.
    self associationsDo:
        [ :assoc | (aBlock value: assoc value)
                     ifTrue: [ newDict add: assoc ] ].
    ^newDict
!

reject: aBlock
    self shouldNotImplement
!

inject: value into: aBlock
    self shouldNotImplement
! !

! Dictionary methodsFor: 'misc math methods'!

= aDictionary
    self class == aDictionary class
        ifFalse: [ ^false ].
    tally ~= aDictionary size ifTrue: [ ^false ].
    self associationsDo:
        [ :assoc | assoc value ~= (aDictionary at: assoc key
                                               ifAbsent: [ ^false ])
                     ifTrue: [ ^false ] ].
    ^true
!

hash
    | hashValue |
    hashValue <- tally.
    self associationsDo:
        [ :assoc | hashValue <- hashValue + assoc hash ].
    ^hashValue
! !

! Dictionary methodsFor: 'printing'!

printOn: aStream
    aStream nextPutAll: self class name , ' (' .
    self associationsDo:
        [ :assoc | aStream print: assoc.
                   aStream nextPut: Character space ].
    aStream nextPut: $)
! !

! Dictionary methodsFor: 'storing'!

storeOn: aStream
    | hasElements |
    aStream nextPutAll: '(', self class name , ' new'.
    hasElements <- false.
    self associationsDo:
        [ :assoc | aStream nextPutAll: ' at: '.
                   aStream store: assoc key.
                   aStream nextPutAll: ' put: '.
                   aStream store: assoc value.
                   aStream nextPut: $;.
                   hasElements <- true ].
    hasElements ifTrue: [ aStream nextPutAll: ' yourself' ].
    aStream nextPut: $)
! !

! Dictionary methodsFor: 'private' !

findObjectIndex: anObject
	"Finds an object, if no space, grows Set."
	^ self findIndexOrNil: anObject ifFull: [
		 self grow.
		 ^ self findIndexOrNil: anObject ifFull: [ ^ nil ]
		].
!

findIndexOrNil: aKey ifFull: aBlock
	" Try and find the object in the array, return index or nil "
	| index wrap size assoc |
	size <- self basicSize.
	index <- 1 + (aKey hash \\ (size - 1)).
	wrap <- false.
	[ true ] whileTrue: [
		assoc <- self basicAt: index.
		(assoc isNil or: [assoc key = aKey]) ifTrue: [ ^ index ].
		index <- index + 1.
		index > size ifTrue: [
			wrap ifTrue: [ ^ aBlock value ].
			index <- 1.
			wrap <- true.
		]
	]
!

rehashAfterIndex: startIndex
	"Adjust objects if after index"
	| index i size count element |
	index <- startIndex.
	i <- index.
	size <- self basicSize.
	count <- size.
	[  count > 0 ] whileTrue:
		[ i <- i \\ size + 1.
		  element <- self basicAt: i.
		  element isNil ifTrue: [ ^self ].
		  (1 + (element key hash \\ (size - 1))) = index 
		      ifTrue: [ self basicAt: index put: element.
		   	        self basicAt: i put: nil.
			        index <- i ].
		  count <- count - 1
	]
!

grow
	| newDict |
	newDict <- self species new: self basicSize + self growSize.
	self associationsDo: [ :element | newDict add: element ].
	^ self become: newDict
!

errorKeyNotFound: aKey
    self error: ('Key "', aKey asString , '" not found: ')
! !

IdentityDictionary comment:
'I am similar to dictionary, except that my representation is
different, and I use the object identity comparision message == to
determine equivalence of indices.' !

! IdentityDictionary class methodsFor: 'instance creation'!

new
    ^self new: 4
!

new: anInteger
    ^(super new: anInteger) initValues

! !

! IdentityDictionary methodsFor: 'accessing'!

add: anAssociation
    self at: anAssociation key put: anAssociation value.
    ^anAssociation
!

at: key put: value
    | index |
    index <- self findKeyIndex: key.
    (self basicAt: index) isNil
        ifTrue: [ tally <- tally + 1 ].
    self basicAt: index put: key.
    values basicAt: index put: value.
    ^value
!

at: key ifAbsent: aBlock
    | index |
    index <- self findKeyIndex: key.
    (self basicAt: index) isNil
        ifTrue: [ ^aBlock value ].
    ^values basicAt: index
!    
    
associationAt: key ifAbsent: aBlock
    | index assoc|
    ^Association key: key value: (self at: key ifAbsent: [ ^aBlock value ])
!

keyAtValue: value ifAbsent: exceptionBlock
    self indicesDo:
        [ :i | value = (values basicAt: i)
                 ifTrue: [ ^self basicAt: i] ].
    ^exceptionBlock value
! !

! IdentityDictionary methodsFor: 'testing'!

includesAssociation: anAssociation
    | index |
    index <- self findKeyIndex: anAssociation key.
    ^(self basicAt: index) notNil
        and: [ (values basicAt: index) = anAssociation value ]
!

includesKey: key
    ^(self basicAt: (self findKeyIndex: key)) notNil
! !

! IdentityDictionary methodsFor: 'removing'!

removeKey: key ifAbsent: aBlock
    | index value|
    index <- self findKeyIndexNoGrow: key ifAbsent: [ ^aBlock value ].
    value <- values basicAt: index.
    self basicAt: index put: nil.
    values basicAt: index put: nil.
    tally <- tally - 1.
    self rehashObjectsAfter: index.
    ^ value
! !

! IdentityDictionary methodsFor: 'enumerating'!

associationsDo: aBlock
    self indicesDo:
        [ :i | aBlock value: (Association key: (self basicAt: i)
                                          value: (values basicAt: i)) ]
!

"These could be implemented more efficiently by 
 doing the explicit scanning of the dictionary by hand"
keysDo: aBlock
    self indicesDo: [ :i | aBlock value: (self basicAt: i) ]
!

do: aBlock
    self indicesDo: [ :i | aBlock value: (values basicAt: i) ]
!

select: aBlock
    | newDict |
    newDict <- self species new.
    self indicesDo:
        [ :i | (aBlock value: (values basicAt: i))
                 ifTrue: [ newDict add: (Association key: (self basicAt: i)
                                                    value: (values basicAt: i))]
 ].
    ^newDict
! !

! IdentityDictionary methodsFor: 'misc math methods'!

= aDictionary
    self class == aDictionary class
        ifFalse: [ ^false ].
    tally ~= aDictionary size ifTrue: [ ^false ].
    self indicesDo:
        [ :i | (values basicAt: i) = (aDictionary at: (self basicAt: i)
                                                  ifAbsent: [ ^false ])
                 ifFalse: [ ^false ] ].
    ^true
!

hash
    | hashValue |
    hashValue <- tally.
    self indicesDo:
        [ :i | hashValue <- hashValue + (self basicAt: i) hash.
               hashValue <- hashValue + (values basicAt: i) hash ].
    ^hashValue
! !

! IdentityDictionary methodsFor: 'printing'!

printOn: aStream
    aStream nextPutAll: self class name , ' ('.
    aStream nl.
    self indicesDo:
        [ :i | aStream tab.
               aStream print: (self basicAt: i).
               aStream nextPutAll: '->'.
               aStream print: (values basicAt: i).
               aStream nl ].
    aStream nextPut: $)
! !

! IdentityDictionary methodsFor: 'storing'!

storeOn: aStream
    | hasElements |
    aStream nextPutAll: '(', self class name , ' new'.
    hasElements <- false.
    self indicesDo:
        [ :i | aStream nextPutAll: ' at: '.
               aStream store: (self basicAt: i).
               aStream nextPutAll: ' put: '.
               aStream store: (values basicAt: i).
               aStream nextPut: $;.
               hasElements <- true ].
    hasElements ifTrue: [ aStream nextPutAll: ' yourself' ].
    aStream nextPut: $)
! !

! IdentityDictionary methodsFor: 'private methods'!

initValues
    values <- Array new: self basicSize
!

indicesDo: aBlock
    "Invokes aBlock with all the indices of the set that have valid keys"
    1 to: self basicSize do:
        [ :i | (self basicAt: i) notNil
                  ifTrue: [ aBlock value: i ] ]
!    

rehashObjectsAfter: anIndex
    "Rehashes all the objects in the collection after index to see if any of
    them hash to index.  If so, that object is copied to index, and the
    process repeats with that object's index, until a nil is encountered."
    | i size count key index |
    index <- anIndex.
    i <- index.
    size <- self basicSize - 1.
    count <- size + 1.
    [ count > 0 ]
        whileTrue:
            [ i <- i \\ size + 1.
              key <- self basicAt: i.
              key isNil ifTrue: [ ^self ].
              (1 + (key hash \\ (size - 1))) = index
                ifTrue: [ self basicAt: index put: key.
                          values basicAt: index put: (values basicAt: i).
                          self basicAt: i put: nil.  "Be tidy"
                          values basicAt: i put: nil."Be tidy"
                          index <- i ].
              count <- count - 1 ]
!

findKeyIndex: aKey ifFull: aBlock
    "Tries to see if aKey exists as the key of an indexed variable (which is an
    association).  If it's searched the entire dictionary and the key is 
    not to be found, aBlock is evaluated and it's value is returned."
    | index count size key |
    size <- self basicSize.
    index <- 1 + (aKey hash \\ (size - 1)).
    count <- size.
    [ count > 0 ]
        whileTrue:
            [ key <- self basicAt: index.
              (key isNil or: [ key == aKey ])
                ifTrue: [ ^index ].
	      index <- index + 1.
	      index > size ifTrue: [index <- 1 ].
              count <- count - 1. ].
    ^aBlock value
!
            
findKeyIndex: aKey
    "Finds an association with the given key in the dictionary and returns its
    index.  If the dictionary doesn't contain the object and there is no nil
    element, the dictionary is grown and then the index of where the object
    would go is returned."
    ^self findKeyIndex: aKey
          ifFull: [ self grow.
                    self findKeyIndex: aKey
                         ifFull: [ ^self error: 'failed to grow a new empty el
ement!!' ] ]
!

grow
    | newDict |
    newDict <- self species new: self basicSize + self growSize.
    self indicesDo: [ :i | newDict at: (self basicAt: i)
                                   put: (values basicAt: i) ].
    ^self become: newDict
!

growSize
    ^32

! !



Collection subclass: 'MappedCollection' instanceVariableNames: 'domain map'
           classVariableNames: '' poolDictionaries: '' category: nil!

MappedCollection comment: 
'I represent collections of objects that are indirectly indexed by names.
There are really two collections involved: domain and a map.  The map maps
between external names and indices into domain, which contains the
real association.  In order to work properly, the domain and map objects must
be instances of a subclass of SequenceableCollection or Dictionary. ' !

! MappedCollection class methodsFor: 'basic'!

collection: aCollection map: aMap
    ^self new setCollection: aCollection andMap: aMap
!

new
    self error: 'new not available for MappedCollections; use collection:map:'
! !


! MappedCollection methodsFor: 'basic'!

at: key
    ^domain at: (map at: key)
!

at: key put: value
    ^domain at: (map at: key) put: value
!

contents
    | contents |
    contents <- Bag new.
    map do: [ :domainKey | contents add: domain at: domainKey ].
    ^contents
!

size
    ^domain size
!

add: anObject
    self shouldNotImplement
!

contents
    | aBag |
    aBag <- Bag new.
    map do: [ :value | aBag add: (domain at: value) ].
    ^aBag
!

do: aBlock
    map do: [ :value | aBlock value: (domain at: value) ]
!

collect: aBlock
    | aStream |
    aStream <- WriteStream on: (self species new: self size).
    self do: [ :value | aStream nextPut: (aBlock value: value) ].
    ^aStream contents
!

select: aBlock
    | aStream |
    aStream <- WriteStream on: (self species new: self size).
    self do: [ :value | (aBlock value: value) ifTrue:
                [ aStream nextPut: value ] ].
    ^aStream contents
! !

! MappedCollection methodsFor: 'private'!

setCollection: aCollection andMap: aMap
    domain <- aCollection.
    map <- aMap
!

species
    ^domain species
! !

! Collection methodsFor: 'converting'!

asBag
    | aBag |
    aBag <- Bag new.
    self do: [ :each | aBag add: each ].
    ^aBag
!

asOrderedCollection
    | anOrderedCollection |
    anOrderedCollection <- OrderedCollection new: self size.
    self do: [ :each | anOrderedCollection add: each ].
    ^anOrderedCollection
!

asSet
    | aSet |
    aSet <- Set new: self size.
    self do: [ :each | aSet add: each ].
    ^aSet
!

asSortedCollection
    | aSortedCollection |
    aSortedCollection <- SortedCollection new.
    aSortedCollection addAll: self.
    ^aSortedCollection
!

asSortedCollection: aBlock
    | aSortedCollection |
    aSortedCollection <- SortedCollection new.
    aSortedCollection sortBlock: aBlock.
    aSortedCollection addAll: self.
    ^aSortedCollection
! !

! Collection methodsFor: 'printing'!

printOn: aStream
    | tooMany |
    tooMany <- aStream position + self maxPrint.
    aStream nextPutAll: self class name, ' ('.
    self do:
        [ :element |
	  aStream position > tooMany
	    ifTrue: [aStream nextPutAll: ' ...etc...)'. ^ self].
	 element printOn: aStream.
         aStream space ].
    aStream nextPut: $)
! !

! Collection methodsFor: 'storing'!

storeOn: aStream
    | noneYet |
    aStream nextPutAll: '(('.
    aStream nextPutAll: self class name.
    aStream nextPutAll: ' new)'.
    noneYet <- true.
    self do:
        [ :each |
           noneYet 
	     ifTrue: [ noneYet <- false]
	     ifFalse: [ aStream nextPut: $; ].
	     aStream nextPutAll: ' add: '.
             each storeOn: aStream].
    noneYet ifFalse: [ aStream nextPutAll: '; yourself' ].
    aStream nextPut: $)
! !


