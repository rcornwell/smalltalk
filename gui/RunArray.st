SequenceableCollection subclass: 'RunArray'
       instanceVariableNames: 'contents runs last length'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Collections' !

RunArray comment: 
 'I work like a OrderedCollection, but I keep my data run length encoded to save space.' !

! RunArray class methodsFor: 'instance creation' !

new
    ^ super new initialize: 0

!

new: size
    ^ super new initialize: size
! !

! RunArray methodsFor: 'accessing' !

at: index
    | location offset |
    (index >= 1 and: [ index <= length])
        ifFalse: [ self error: 'index out of bounds for runarray' ]
        ifTrue: [ offset <- 1.
    		  location <- index.
		  [ location > (runs at: offset) ] whileTrue:
			[ location <- location - (runs at: offset).
			  offset <- offset + 1 ].
		  ^contents at: offset ]
!

lengthAt: index
    | location offset next |
    (index >= 1 and: [ index <= length])
        ifFalse: [ self error: 'index out of bounds for runarray' ]
        ifTrue: [ offset <- 1.
    		  location <- 0.
		  next <- runs at: offset.
		  [ index > next ] whileTrue:
			[ location <- location + next.
			  offset <- offset + 1.
			  next <- runs at: offset
			 ].
		  ^next - (index - location) ]
!

after: oldObject
    "Return the element after oldObject.  Error if oldObject not found or
    if no following object is available"
    1 to: last do:
        [ :index |
            (contents at: index) = oldObject
                ifTrue: [
                    index < last
                        ifTrue: [ ^contents at: index + 1 ]
                        ifFalse: [ ^self error: 'no following object' ] ]
        ].
    self error: 'object not found'
!

before: oldObject
    "Return the element after oldObject.  Error if oldObject not found or
    if no following object is available"
    1 to: last do:
        [ :index |
            (contents at: index) = oldObject
                ifTrue: [
                    index > 1
                        ifTrue: [ ^contents at: index - 1 ]
                        ifFalse: [ ^self error: 'no preceding object' ] ]
        ].
    self error: 'object not found'
!

last
    last = 0 ifTrue: [ self error: 'object empty' ].
    ^ contents at: last
!

indexOf: anElement ifAbsent: exceptionBlock
    | offset |
    offset <- 1.
    1 to: last do:
	[ :index | ( contents at: index) = anElement ifTrue: [ ^ offset ].
		   offset <- offset + (runs at: index)  ].
    ^exceptionBlock value
!

size
    ^ length
! !

! RunArray methodsFor: 'copying' !

copyEmpty
    ^self species new: length
! !

! RunArray methodsFor: 'modifying' !

at: index put: anObject
    | runIndex runOffset len prevIdx nextIdx prevLen prevVal nextLen
	 nextVal idx| 

    runIndex <- nil.
    (index > 0) ifTrue: [
        runOffset <- 1.
        idx <- 1.
        [runIndex isNil and: [idx <= last]] whileTrue: [
            len <- runs at: idx.
            nextIdx <- runOffset + len.
            (index >= runOffset and: [index < nextIdx]) ifTrue: [
               runIndex <- idx.
               nextIdx <- runOffset. 
            ].
            runOffset <- nextIdx.
            idx <- idx + 1
        ]
    ].
    runIndex isNil ifTrue: [
        ^ self error: 'index out of bounds for RunArray collection' 
    ].

    nextVal <- contents at: runIndex.

    " easiest: value there is the same ..."
    nextVal = anObject ifTrue: [ ^ anObject ].

    " if the length is 1, this is an island ..."
    " ... which is either easy, or requires a merge."

    len = 1 ifTrue: [
        " check if it can be merged into the next or previous run"

        runIndex > 1 ifTrue: [
            prevIdx <- runIndex - 1.
            prevVal <- contents at: prevIdx.
            prevVal = anObject ifTrue: [
                " can merge it into previous"

                prevLen <- runs at: prevIdx.

                " check if merge into next is also possible (filling an island)"
                
                (runIndex < (last - 1)) ifTrue: [
                    nextIdx <- runIndex + 1.
                    nextVal <- contents at: nextIdx.
                    nextVal = anObject ifTrue: [
                        " can merge with both."
                        
                        nextLen <- runs at: nextIdx.
			runs at: prevIdx put: prevLen + nextLen + 1.
			self removeSpaces: 2 at: nextIdx + 1.
                        ^ anObject
                    ]
                ].

                runs at: prevIdx put: prevLen+1.
		self removeSpaces: 1 at: runIndex + 1.

                ^ anObject
            ].
        ].

        " check if merge into next is possible"

        (runIndex < (last - 1)) ifTrue: [
            nextIdx <- runIndex + 1.
            nextVal <- contents at: nextIdx.
            nextVal = anObject ifTrue: [
                nextLen <- runs at: nextIdx.
                runs at: nextIdx put: nextLen + 1.
		self removeSpaces: 1 at: runIndex + 1.
                ^ anObject
            ].
        ].

        " no merge; island remains"

        contents at: runIndex put: anObject.
        ^ anObject
    ].

    runOffset == index ifTrue: [
        " at the beginning of that run ..."

        " Check if last value same "

        runIndex > 1 ifTrue: [
            prevIdx <- runIndex - 1.
            prevVal <- contents at: prevIdx.
            prevVal = anObject ifTrue: [
                prevLen <- runs at: prevIdx.
                runs at: prevIdx put: prevLen + 1.
                runs at: runIndex put: len - 1.
                ^ anObject.
            ].
        ].

        " must cut off 1 & insert a new run before .."

        runs at: runIndex put: len - 1.
	self insertSpaces: 1 at: (runIndex - 1).
        runs at: runIndex   put: 1.
        contents at: runIndex put: anObject.
        ^ anObject
    ].

    (runOffset + len - 1) == index ifTrue: [
        " at the end ..."

        " check if its better added to the next run ..."

        (runIndex < (last - 1)) ifTrue: [
            nextIdx <- runIndex + 1.
            nextVal <- contents at: nextIdx.
            nextVal = anObject ifTrue: [
                nextLen <- runs at: nextIdx.
                runs at: nextIdx put: nextLen + 1.
                runs at: runIndex put: len - 1.
                ^ anObject.
            ].
        ].

        " must cut off 1 & insert a new run after .."

        runs at: runIndex put: len - 1.

	" Check if there is room to add one more element "
	self insertSpaces: 1 at: runIndex.
        runs at: runIndex + 1   put: 1.
        contents at: runIndex + 1 put: anObject.
        ^ anObject
    ].

    " hardest - split run into two, insert new run in-between"
    nextVal <- contents at: runIndex.
    nextLen <- runs at: runIndex.
    self insertSpaces: 2 at: runIndex.

    prevLen <- nextLen - (index - runOffset).
    nextLen <- nextLen - prevLen.
    nextLen <- nextLen - 1.

    runs at: runIndex   put: prevLen.
    contents at: runIndex put: nextVal.

    runs at: runIndex+2 put: nextLen.
    contents at: runIndex+2 put: nextVal.

    " insert"
    runs at: runIndex+1 put: 1.
    contents at: runIndex+1 put: anObject.

    ^ anObject
!

atAllPut: anObject
    runs at: 1 put: length.
    contents at: 1 put: anObject.
    last <- 1.
!

from: start to: stop put: anObject
    | runIndex runOffset len prevIdx nextIdx prevLen prevVal nextLen nextVal
       idx endIndex endOffset |

    " Check if only one item to insert "
    (stop - start = 1) ifTrue: [ ^ self at: start put: anObject ].
    runIndex <- nil.
    (start > 0) ifTrue: [
        runOffset <- 1.
        idx <- 1.
        [runIndex isNil and: [idx <= last]] whileTrue: [
            len <- runs at: idx.
            nextIdx <- runOffset + len.
            (start >= runOffset and: [start < nextIdx]) ifTrue: [
               runIndex <- idx.
               nextIdx <- runOffset
            ].
            runOffset <- nextIdx.
            idx <- idx + 1
        ]
    ].
    runIndex isNil ifTrue: [
        ^ self error: 'index out of bounds for RunArray collection' 
    ].

    nextVal <- contents at: runIndex.

    " easiest: value there is the same ..."
    (nextVal = anObject and: [ stop - start = len ]) ifTrue: [ ^ anObject ].

    endIndex <- nil.
    endOffset <- runOffset.
    [ endIndex isNil and: [ idx <= last]] whileTrue: [
	nextIdx <- endOffset + (runs at: idx).
	(stop >= endOffset and: [ stop < nextIdx]) ifTrue: [
	   endIndex <- idx.
	   nextIdx <- endOffset
	].
	endOffset <- nextIdx.
	idx <- idx + 1
    ].
    endIndex isNil ifTrue: [
        ^ self error: 'index out of bounds for RunArray collection' 
    ].

    len <- stop - start.

    " at the beginning of that run ..."
    runOffset == start ifTrue: [
	" Clear off stuff inbetween "
	endIndex = runIndex ifFalse: [
	    nextLen <- len - (endOffset - runOffset).
	    self removeSpace: endIndex - runIndex at: runIndex.
	    endIndex <- runIndex.
	] ifTrue: [
	    nextLen <- len
        ].

        " Check if last value same "

        runIndex > 1 ifTrue: [
            prevIdx <- runIndex - 1.
            prevVal <- contents at: prevIdx.
            prevVal == anObject ifTrue: [
                prevLen <- runs at: prevIdx.
                runs at: prevIdx put: prevLen + len.
	        nextLen <- (runs at: runIndex) - nextLen.
	        " If nothing left in block, remove it. "
	        nextLen = 0 ifTrue: [
		    self removeSpace: 1 at: endIndex
	        ] ifFalse: [
		    runs at: runIndex put: nextLen
		].
                ^ anObject.
            ].
        ].


	prevVal <- contents at: runIndex.
	" Current item same? "
	prevVal == anObject ifTrue: [
	    runs at: runIndex put: (runs at: runIndex) + (len - nextLen).
	    ^ anObject
	].

 	" Carve off a chunk at start of this run "
	nextLen > len ifTrue: [
	    runs at: runIndex put: (nextLen - len).
	    self insertSpace: 1 at: runIndex.
	    runs at: runIndex put: (stop - start).
	    ^ contents at: runIndex put: anObject
	].

        nextLen <- (runs at: runIndex) - len.
        " If nothing left in block, remove it. "
        nextLen = 0 ifTrue: [
	    self removeSpace: 1 at: endIndex
        ] ifFalse: [
	    runs at: runIndex put: nextLen
	].
        ^ anObject.
    ].

    " hardest - split run into two, insert new run in-between"
    nextVal <- contents at: runIndex.
    nextLen <- runs at: runIndex.
    self insertSpaces: 2 at: runIndex.

    prevLen <- nextLen - (len - runOffset).
    nextLen <- nextLen - prevLen.
    nextLen <- nextLen - len.

    runs at: runIndex   put: prevLen.
    contents at: runIndex put: nextVal.

    runs at: runIndex+2 put: nextLen.
    contents at: runIndex+2 put: nextVal.

    " insert"
    runs at: runIndex+1 put: len.
    contents at: runIndex+1 put: anObject.

    ^ anObject

! !

! RunArray methodsFor: 'adding' !

add: anObject
    ^self addLast: anObject
!

add: newObject after: oldObject
    | val idx |
    idx <- 1.
    [idx <= last] whileTrue: [
	val <- contents at: idx.
	(val == oldObject) ifTrue: [
	    " Merge with existing. "
	    (newObject == oldObject) ifTrue: [
	       runs at: idx put: 1 + (runs at: idx).
	       length <- length + 1.
	       ^ newObject
	    ].
	    " If at end of object, append on end "
	    idx = last ifTrue: [ ^ self addLast: newObject ].
	    " If not at end see if we can merge with next. "
	    idx <- idx + 1.
	    ((contents at: idx) == newObject) ifTrue: [
	        runs at: idx put: 1 + (runs at: idx).
	        length <- length + 1.
	        ^ newObject
            ].
	    " insert a new object "
	    self insertSpaces: 1 at: idx.
	    runs at: idx put: 1.
	    contents at: idx put: newObject.
	    ^ newObject
        ].
        idx <- idx + 1
    ].
    self error: 'object not found in collection'
!

add: newObject before: oldObject
    | val idx |
    idx <- 1.
    [idx <= last] whileTrue: [
	val <- contents at: idx.
	(val == oldObject) ifTrue: [
	    " Merge with existing. "
	    (newObject == oldObject) ifTrue: [
	       runs at: idx put: 1 + (runs at: idx).
	       length <- length + 1.
	       ^ newObject
	    ].
	    " If at end of object, append on end "
	    idx = 1 ifTrue: [ ^ self addFirst: newObject ].
	    " If not at start see if we can merge with last. "
	    idx <- idx - 1.
	    ((contents at: idx) == newObject) ifTrue: [
	        runs at: idx put: 1 + (runs at: idx).
	        length <- length + 1.
	        ^ newObject
            ].
	    " insert a new object "
	    self insertSpaces: 1 at: idx.
	    runs at: idx put: 1.
	    contents at: idx put: newObject.
	    ^ newObject
        ].
        idx <- idx + 1
    ].
    self error: 'object not found in collection'
!

addFirst: newObject
    | val | 
    last == 0 ifTrue: [ 
	contents at: 1 put: newObject.
	runs at: 1 put: 1.
	last <- 1.
	^ newObject
    ].
    val <- contents at: 1.
    length <- length + 1.
    (newObject == val) ifTrue: [
	runs at: 1 put: 1 + (runs at: 1)
    ] ifFalse: [
	self insertSpaces: 1 at: 1.
	runs at: 1 put: 1.
	contents at: 1 put: newObject
    ].
    ^ newObject
!
    
addLast: newObject
    | val |
    last == 0 ifTrue: [ 
	contents at: 1 put: newObject.
	runs at: 1 put: 1.
	last <- 1.
	^ newObject
    ].
    val <- contents at: last.
    length <- length + 1.
    (newObject == val) ifTrue: [
	runs at: last put: 1 + (runs at: last)
    ] ifFalse: [
	self insertSpaces: 1 at: last.
	runs at: last put: 1.
	contents at: last put: newObject.
    ].
    ^ newObject
!

add: newObject withOccurrences: aCount
    | val |
    last == 0 ifTrue: [ 
	contents at: 1 put: newObject.
	runs at: 1 put: aCount.
	last <- 1.
	^ newObject
    ].
    val <- contents at: last.
    length <- length + aCount.
    (newObject == val) ifTrue: [
	runs at: last put: aCount + (runs at: last)
    ] ifFalse: [
	self insertSpaces: 1 at: last.
	runs at: last put: aCount.
	contents at: last put: newObject.
    ].
    ^ newObject
! !

! RunArray methodsFor: 'removing' !

removeFirst
    | left val |
    last == 0
        ifTrue: 
            [ ^self error: 'attempted to remove from an empty collection' ].
    val <- contents at: 1.
    left <- runs at: 1 put: 1 - (runs at: 1).
    left == 0 ifTrue: [ self  removeSpaces: 1 at: 1].
    length <- length - 1.
    ^ val
!

removeLast
    | left val |
    last == 0
        ifTrue: 
            [ ^self error: 'attempted to remove from an empty collection' ].
    val <- contents at: last.
    left <- runs at: last put: 1 - (runs at: last).
    left == 0 ifTrue: [ last <- last - 1 ].
    length <- length - 1.
    ^ val
! !

! RunArray methodsFor: 'private' !

initialize: size
    last <- 1.
    length <- size.
    contents <- Array new: self growSize.
    runs <- Array new: self growSize.
    contents at: 1 put: nil.
    runs at: 1 put: length.
!

" Insert a empty element at index " 
insertSpaces: number at: index
| newArray |
" Check if there is room to add one more element "
    ((last + number) < contents size) ifFalse: [
	newArray <- Array new: (last + self growSize).
	newArray replaceFrom: 1 to: index
		with: runs startingAt: 1.
	newArray replaceFrom: (index + number + 1) to: (last + number)
		with: runs startingAt: index.
	runs <- newArray.
	newArray <- Array new: (last + self growSize).
	newArray replaceFrom: 1 to: index
		with: contents startingAt: 1.
	newArray replaceFrom: (index + number + 1) to: (last + number)
		with: contents startingAt: index.
	contents <- newArray.
    ] ifTrue: [
	last to: (index + number) by: -1 do: [ :i |
	    runs at: (i + number) put: (runs at: i).
	    contents at: (i + number) put: (contents at: i)
	]
    ].
    last <- last + number
!

" remove a element at index "
removeSpaces: number at: index
    index to: (last - number) do: [ :i |
	runs at: i put: (runs at: (i + number)).
	contents at: i put: (contents at: (i + number)).
    ].
    last <- last - number
!
 
growSize
    ^ 32
!

runs
    ^ runs
!

contents
    ^ contents
!

lastValid
    ^ last
! !

! RunArray methodsFor: 'testing' !

includes: anObject
    contents do: [ :element | anObject = element ifTrue: [ ^true ]].
    ^false
!

occurrencesOf: anObject
    | tally v |
    tally <- 0.
    1 to: last do: [ :index |
		(anObject = (contents at: index))
		 ifTrue: [ tally <- tally + (runs at: index)].
    ^tally
! !

! RunArray methodsFor: 'comparing' !

= aCollection
    | size c r l |
    self == aCollection ifTrue: [ ^true ].
    self species == aCollection species ifFalse: [ ^false ].
    (size <- self size) == aCollection size ifFalse: [ ^false ].
    (l <- aCollection lastValid) == last ifFalse: [ ^ false ].
    r <- aCollection runs.
    c <- aCollection contents.
    1 to: l do:
        [ :i | (contents at: i) = (c at: i)
                   ifFalse: [ ^false ].
	       (runs at: i) = (r at: i)
		   ifFalse: [ ^ false ]
	].
    ^true
! !

! RunArray methodsFor: 'enumerating' !

do: aBlock
    "Evaluate aBlock for all elements in the sequenceable collection"
    | val |
    1 to: last do: [ :i |
	val <- contents at: i.
	1 to: (runs at: i) do: [ :i2 | aBlock value: val ]
    ]
!

runsDo: aBlock
    "Evaluate aBlock for each run block "
    1 to: last do: [ :i |
	aBlock value: (runs at: i) value: (contents at: i)
	]
!

findFirst: aBlock
    "Returns the index of the first element of the sequenceable collection
    for which aBlock returns true"
    | idx |
    idx <- 1.
    1 to: last do:
        [ :i | (aBlock value: (contents at: i))
                 ifTrue: [ ^idx ].
	       idx <- idx + runs at: i
	 ].
    ^0
!

findLast: aBlock
    | idx |
    idx <- length.
    last to: 1 by: -1 do:
        [ :i | (aBlock value: (contents at: i))
                 ifTrue: [ ^idx ].
		idx <- idx - runs at: i
	 ].
    ^0
! !

! Collection methodsFor: 'converting' !

asRunArray
   | aRunArray |
   aRunArray <- RunArray new.
   self do: [ :e | aRunArray add: e ]
   ^ aRunArray
! !

