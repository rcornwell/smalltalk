

SequenceableCollection subclass: 'RunArray'
	instanceVariableNames: 'contentsArray'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections'
!

RunArray comment: 'This implements an ordered collection which uses runs to minimise the amount
 of data that it holds. Basically it should be used if you know that an ordered
 collections is giong to contain a lot of runs of eactly the same data. Implemented
 to allow simultation playback, since the ordered collctions which that generates
 are so big that the complier falls over, though most of it is extremely repetetive.
 This should be totally abstracted. The user should not be a ble to see the difference
 between an ordered collection and a ComrpessedOrderedCollection.  This has a
 lot in common with RunArray, and the two should probably share implementation.
 but I could not do some of the things I wanted with the RunArray code, so this
 is all done on its own.
	Some of this could be made faster by adding a cache of the start and finish
 indices of each run, but since I envisage that most additions etc. will be to
 and from the end those are not included. In addition I have implemented the
 bare essentials of this for what I need it for - i.e. add to the end and take
 off the beginning.' !


! RunArray class methodsFor: 'instance creation' !

from: aSequencableCollection
    "return a new runArray, containing the elements from aSequencableCollection"

    ^ self basicNew setElementsFrom: aSequencableCollection

    "
     RunArray from: #(1 2 3 3 3 4 5 5 6 6 6 6 6 6)
    "
!

new: count
    "return a new runArray, containing count elements - all nil"

    ^ self basicNew setElement: nil occurrences: count
!

new: count withAll: anObject
    "create a new runArray with count elements, all being anObject"

    ^ self basicNew setElement: anObject occurrences: count

    "
     RunArray new: 100 withAll: #hello
    "
! !

! RunArray methodsFor: 'accessing' !

at: index 
    "Answer the element at index. 
     at:  is used by a knowledgeable client to access an existing element 
     This is a pretty dumb thing to do to a runArray and it is 
     not at all efficient (think of that as a discouragement)."

    | position nRuns runLen | 

    (index > 0) ifTrue: [
        position <- 1.
        nRuns <- contentsArray size.
        1 to: nRuns by: 2 do: [ :runIndex | 
            runLen <- contentsArray at: runIndex.
            index >= position ifTrue: [
                index < (position + runLen) ifTrue: [
                    ^ contentsArray at: (runIndex + 1)
                ].
            ].
            position <- position + runLen
        ]
    ].
    ^ self subscriptBoundsError: index

    "
     | c| 

     c <- RunArray new.
     c add: 1; add: 1; add: 1; add: 2; add: 2; add: 3; add: 3; add: 4; add: 5.
     c at: 1. 
     c at: 2. 
     c at: 3. 
     c at: 4.  
     c at: 5. 
     c at: 6. 
     c at: 7. 
     c at: 8.  
     c at: 9.  
     c at: 10.  
    "

!

at: index put: anObject 
    "Put anObject at element index anInteger.      
     at:put: can not be used to append, front or back, to a runArray.      
     It is used by a knowledgeable client to replace an element. 
     This is a pretty dumb thing to do to a runArray and it is 
     very inefficient, since we have to check if runs are to be merged or
     splitted."

    | runSz runIndex runOffset len l1 l2 prevIdx nextIdx
     val newRuns prevLen prevVal nextLen nextVal idx| 

    runSz <- contentsArray size.

    runIndex <- nil.
    (index > 0) ifTrue: [
        runOffset <- 1.
        idx <- 1.
        [runIndex isNil and: [idx < runSz]] whileTrue: [
            len <- contentsArray at: idx.
            nextIdx <- runOffset + len.
            index >= runOffset ifTrue: [
                index < nextIdx ifTrue: [
                    runIndex <- idx.
                    nextIdx <- runOffset. " dont advance"
                ].
            ].
            runOffset <- nextIdx.
            idx <- idx + 2.
        ]
    ].
    runIndex isNil ifTrue: [
        ^ self subscriptBoundsError: index
    ].

    val <- contentsArray at: (runIndex + 1).

    " easiest: value there is the same ..."

    val = anObject ifTrue: [
        ^ anObject
    ].

    " if the length is 1, this is an island ..."
    " ... which is either easy, or requires a merge."

    len <- contentsArray at: runIndex.
    len = 1 ifTrue: [
        " check if it can be merged into the next or previous run"

        runIndex > 1 ifTrue: [
            prevIdx <- runIndex - 2.
            prevVal <- contentsArray at: (prevIdx + 1).
            prevVal = anObject ifTrue: [
                " can merge it into previous"

                prevLen <- contentsArray at: prevIdx.

                " check if merge into next is also possible (filling an island)"
                
                runIndex < (runSz - 1) ifTrue: [
                    nextIdx <- runIndex + 2.
                    nextVal <- contentsArray at: (nextIdx + 1).
                    nextVal = anObject ifTrue: [
                        " can merge with both."
                        
                        nextLen <- contentsArray at: nextIdx.

                        contentsArray at: prevIdx put: prevLen+nextLen+1.
                        runSz <- (runSz - 4).
                        newRuns <- Array new: runSz.
                        newRuns replaceFrom: 1 to: (prevIdx + 1)
				 with: contentsArray startingAt: 1.
                        newRuns replaceFrom: runIndex to: runSz
				 with: contentsArray startingAt: nextIdx+2.
                        contentsArray <- newRuns.
                        ^ anObject
                    ]
                ].

                contentsArray at: prevIdx put: prevLen+1.

                runSz <- (runSz - 2).
                newRuns <- Array new: runSz.
                newRuns replaceFrom: 1 to: (runIndex - 1)
			 with: contentsArray startingAt: 1.
                newRuns replaceFrom: runIndex to: runSz
			 with: contentsArray startingAt: runIndex+2.
                contentsArray <- newRuns.

                ^ anObject
            ].
        ].

        " check if merge into next is possible"

        runIndex < (runSz-1) ifTrue: [
            nextIdx <- runIndex + 2.
            nextVal <- contentsArray at: nextIdx+1.
            nextVal = anObject ifTrue: [
                nextLen <- contentsArray at: nextIdx.
                contentsArray at: nextIdx put: nextLen + 1.

                runSz <- (runSz - 2).
                newRuns <- Array new: runSz.
                newRuns replaceFrom: 1 to: (runIndex - 1)
			 with: contentsArray startingAt: 1.
                newRuns replaceFrom: runIndex to: runSz
			 with: contentsArray startingAt: nextIdx.
                contentsArray <- newRuns.
                ^ anObject
            ].
        ].

        " no merge; island remains"

        contentsArray at: (runIndex+1) put: anObject.
        ^ anObject
    ].

    runOffset == index ifTrue: [
        " at the beginning of that run ..."

        " check if its better added to the previous run ..."

        runIndex > 1 ifTrue: [
            prevIdx <- runIndex - 2.
            prevVal <- contentsArray at: prevIdx+1.
            prevVal = anObject ifTrue: [
                prevLen <- contentsArray at: prevIdx.
                contentsArray at: prevIdx put: prevLen + 1.
                contentsArray at: runIndex put: len - 1.
                ^ anObject.
            ].
        ].

        " must cut off 1 & insert a new run before .."

        contentsArray at: runIndex put: len - 1.

        runSz <- (runSz + 2).
        newRuns <- Array new: runSz.
        newRuns replaceFrom: 1 to: (runIndex - 1) 
		with: contentsArray startingAt: 1.
        newRuns replaceFrom: runIndex+2 to: runSz 
		with: contentsArray startingAt: runIndex.
        contentsArray <- newRuns.

        contentsArray at: runIndex   put: 1.
        contentsArray at: runIndex+1 put: anObject.
        ^ anObject
    ].

    (runOffset + len - 1) == index ifTrue: [
        " at the end ..."

        " check if its better added to the next run ..."

        runIndex < (runSz-1) ifTrue: [
            nextIdx <- runIndex + 2.
            nextVal <- contentsArray at: nextIdx+1.
            nextVal = anObject ifTrue: [
                nextLen <- contentsArray at: nextIdx.
                contentsArray at: nextIdx put: nextLen + 1.
                contentsArray at: runIndex put: len - 1.
                ^ anObject.
            ].
        ].

        " must cut off 1 & insert a new run after .."

        contentsArray at: runIndex put: len - 1.

        runSz <- (runSz + 2).
        newRuns <- Array new: runSz.
        newRuns replaceFrom: 1 to: (runIndex + 1) 
		with: contentsArray startingAt: 1.
        newRuns replaceFrom: runIndex+4 to: runSz 
		with: contentsArray startingAt: runIndex+2.
        contentsArray <- newRuns.

        contentsArray at: runIndex+2 put: 1.
        contentsArray at: runIndex+2+1 put: anObject.
        ^ anObject
    ].

    " hardest - split run into two, insert new run in-between"

    runSz <- (runSz + 4).
    newRuns <- Array new: runSz.

    runIndex > 1 ifTrue: [
        newRuns replaceFrom: 1 to: runIndex-1 with: contentsArray.
    ].
    newRuns replaceFrom: runIndex+6 to: runSz with: contentsArray 
	startingAt: runIndex+2.

    l2 <- len - (index - runOffset).
    l1 <- len - l2.
    l2 <- l2 - 1.

    newRuns at: runIndex   put: l1.
    newRuns at: runIndex+1 put: val.

    newRuns at: runIndex+4 put: l2.
    newRuns at: runIndex+5 put: val.

    " insert"
    newRuns at: runIndex+2 put: 1.
    newRuns at: runIndex+3 put: anObject.

    contentsArray <- newRuns.
    ^ anObject

    "
     | c| 

     Transcript cr.

     c <- RunArray new.
     c add: 1; add: 1; add: 1; add: 2; add: 2; add: 3; add: 3; add: 4;
		 add: 5; yourself.
     Transcript showCR: c.   

     c at: 1 put: $a.
     Transcript showCR: c.   
     c.

     c at: 3 put: $a.
     Transcript showCR: c.   
     c.

     c at: 4 put: $a.   
     Transcript showCR: c.   
     c.

     c at: 5 put: $a.   
     Transcript showCR: c.   
     c.

     c at: 2 put: $0.   
     Transcript showCR: c.   
     c.

     c at: 2 put: $a.   
     Transcript showCR: c.   
     c.

     Transcript showCR: c.   
    "

!

size
    "Answer how many elements the receiver contains.
     Thsi is not the number of runs (but the simulated number of elements)."

    | n runSz | 

    n <- 0.
    runSz <- contentsArray size.
    1 to: runSz by: 2 do: [ :i | 
        n <- n + (contentsArray at: i)
    ].
    ^ n
! !

! RunArray methodsFor: 'adding' !

add: newObject
    "add newObject at the end; returns the object (sigh)"

    ^ self add: newObject withOccurrences: 1.
!

add: newObject withOccurrences: n
    "add newObject n times at the end; returns the object (sigh)"

    | lastIdx runSz newRuns| 

    contentsArray notNil ifTrue: [
        " check for merge"

        runSz <- contentsArray size.

        (contentsArray at: runSz) = newObject ifTrue: [
            lastIdx <- runSz - 1.
            contentsArray at: lastIdx put: (contentsArray at: lastIdx) + n.
            ^ newObject
        ].

        newRuns <- Array new: (runSz + 2).
        newRuns replaceFrom: 1 to: runSz with: contentsArray.
        newRuns at: runSz+1 put: n.
        newRuns at: runSz+2 put: newObject.
        contentsArray <- newRuns.
    ] ifFalse: [
        contentsArray <- Array with: n with: newObject.
    ].
    ^ newObject

    "
     | c| 

     c <- RunArray new.
     c add: 1 withOccurrences: 1000; yourself.
     c add: 2 withOccurrences: 1000; yourself.
    "
!

grow: howBig
    "grow or shrink the receiver to contain howBig elements.
     If growing, new slots will be filled (logically) with nil."

    | sz info runIndex runOffset runSz newRuns| 

    sz <- self size.

    howBig == sz ifTrue: [^ self].

    howBig == 0 ifTrue: [
        contentsArray <- nil.
        ^ self.
    ].

    contentsArray isNil ifTrue: [
        contentsArray <- Array with: howBig with: nil.
        ^ self
    ].

    runSz <- contentsArray size.

    howBig > sz ifTrue: [
        newRuns <- Array new: (runSz + 2).
        newRuns replaceFrom: 1 to: runSz with: contentsArray startingAt: 1.
        newRuns at: (runSz+1) put: (howBig - sz).
        contentsArray <- newRuns.
        ^ self
    ].

    " shrinking; possibly cut of a run"

    info <- self runIndexAndStartIndexForIndex: howBig.
    runIndex <- info at: 1.
    runOffset <- info at: 2.

    howBig == (runOffset - 1) ifTrue: [
        " we are lucky - new size is up-to previous run"

        contentsArray <- contentsArray copyFrom: 1 to: runIndex-1.
    ] ifFalse: [
        contentsArray <- contentsArray copyFrom: 1 to: (runIndex+1).
        contentsArray at: runIndex put: (howBig - runOffset + 1)
    ].

    "
     | c| 

     c <- RunArray new.
     c addAll: #(1 2 3 4 4 4 4 5 5 5 1 2 3); yourself.

     c grow: 50; yourself.

     c grow: 7; yourself.

     c grow: 6; yourself.

     c grow: 0; yourself.
    "
! !

! RunArray methodsFor: 'converting' !

asOrderedCollection
    "return a new orderedCollection, containing the receivers elements."

    | newCollection| 

    contentsArray isNil ifTrue: [^ OrderedCollection new].

    newCollection <- OrderedCollection new: (self size).
    contentsArray pairWiseDo: [ :len :value | 
        newCollection add: value withOccurrences: len
    ].
    ^ newCollection

    "
     | r| 

     r <- RunArray withAll: #(1 2 3 3 3 3 4 4 4 5 6 7 7 7 7 7 7 7).
     Transcript showCR: r.
     Transcript showCR: r asOrderedCollection
    "
!

asRunArray
    "return the receiver itself"
    ^ self
! !

! RunArray methodsFor: 'copying' !

copyFrom: start to: stop
    "return a new collection, containing the elements from start to stop"

    | runStart runNext newRuns idx copying| 

    (contentsArray notNil 
    and: [stop >= start]) ifTrue: [
        newRuns <- self species new.
        runStart <- 1.
        idx <- start.
        copying <- false.
        contentsArray pairWiseDo: [ :len :val |  
            runNext <- runStart + len.
        
            copying ifFalse: [
                idx >= runStart ifTrue: [
                    copying <- true
                ]
            ].
            copying ifTrue: [
                idx < runNext ifTrue: [
                    " found the first run"

                    stop < runNext ifTrue: [
                        newRuns add: val withOccurrences: (stop-idx+1).
                        ^ newRuns
                    ].

                    newRuns add: val withOccurrences: (runNext-idx).
                    idx <- runNext.
                ].
            ].
            runStart <- runNext.
        ]
    ].

    ^ super copyFrom: start to: stop  " for the error report"

    "
     | r| 
     r <- RunArray withAll: #(1 2 3 3 3 3 4 4 4 5 6 7 7 7 7 7 7 7).
     r copyFrom: 1 to: 10  

     | r| 
     r <- RunArray withAll: #(1 2 3 3 3 3 3 3 4 5 6 7 7 7 7 7 7 7).
     r copyFrom: 4 to: 10       

     | r| 
     r <- RunArray withAll: #(1 2 3 3 3 3 3 3 4 5 6 7 7 7 7 7 7 7).
     r copyFrom: 1 to: 20      
    "
! !

! RunArray methodsFor: 'enumerating' !

do: aBlock 
    "Evaluate aBlock with each of the receiver's elements as the 
    argument. "

    contentsArray notNil ifTrue: [
        contentsArray pairWiseDo: [ :len :val |  
            len timesRepeat: [aBlock value: val]
        ]
    ]
!

runsDo: aBlock 
    "Evaluate aBlock with each of the receiver's runs, passing
     length and value as arguments."

    contentsArray notNil ifTrue: [
        contentsArray pairWiseDo: aBlock
    ]
! !

! RunArray methodsFor: 'printing & storing' !

storeOn: aStream 
    "Append to aStream an expression which, if evaluated, will generate   
    an object similar to the receiver."

    aStream nextPutAll:  '(RunArray new'.
    contentsArray notNil ifTrue: [
        contentsArray pairWiseDo: [ :len :val |  
            aStream nextPutAll:  ' add: '
	    aStream nextPutAll: val storeString. 
            len == 1 ifFalse: [
                aStream nextPutAll: ' withOccurrences: '
		aStream nextPutAll: len printString.
            ].
            aStream nextPutAll: ';'
        ].
        aStream nextPutAll: ' yourself'
    ].
    aStream nextPutAll: ')'

    "
     (RunArray new 
        add: 1; 
        add: 1; 
        add: 2; 
        add: 3; 
        add: 4 withOccurrences: 100; 
        add: 5; 
        yourself) storeString 

     RunArray new storeString 
    "
! !

!  RunArray methodsFor: 'private' !

isEmpty
    "Am I empty or not. Returns a boolean"
    ^ contentsArray notNil
!

runIndexAndStartIndexForIndex: anIndex
    "given a logical index, find the index of that run and the logical index
     of the first item in that run."

    | position nRuns runLen runLast| 

    position <- 1.
    nRuns <- contentsArray size.
    1 to: nRuns by: 2 do: [ :runIndex |  
        runLen <- contentsArray at: runIndex.
        anIndex >= position ifTrue: [
            runLast <- position + runLen - 1.
            anIndex <= runLast ifTrue: [
                ^ Array with: runIndex with: position 
            ].
        ].
        position <- position + runLen
    ].

    ^ #(0 0)
!

setElement: newObject occurrences: n
    "private instance setup"
    contentsArray <- Array with: n with: newObject.
!

setElementsFrom: aCollection
    "set my elements from aCollection"
    | nRuns last runLen first dIdx| 

    aCollection size == 0 ifTrue: [^ self].

    " to avoid the reallocations when using"
    " multiple #add: withOccurrences:  calls, "
    " generate the runs collction as an orderedCollection"
    " and convert to an array at the end."

    nRuns <- 0.
    first <- true.
    aCollection do: [ :element | 
        first ifTrue: [
            nRuns <- nRuns + 1.
            last <- element.
            first <- false.
        ] ifFalse: [
            element ~~ last ifTrue: [
                nRuns <- nRuns + 1.
                last <- element.
            ]
        ]
    ].

    " now, we know how many runs there are ..."
    contentsArray <- Array new: (nRuns*2).

    nRuns <- 0.
    runLen <- 0.
    dIdx <- 1.
    aCollection do: [ :element | 
        runLen == 0 ifTrue: [
            last <- element.
            runLen <- 1.
        ] ifFalse: [
            element == last ifTrue: [
                runLen <- runLen + 1.
            ] ifFalse: [
                contentsArray at: dIdx   put: runLen.
                contentsArray at:  dIdx+1 put: last.
                dIdx <- dIdx + 2.
                runLen <- 1.
                last <- element.
            ]
        ]
    ].
    runLen ~~ 0 ifTrue: [
        contentsArray at: dIdx   put: runLen.
        contentsArray at: dIdx+1 put: last.
    ].

    "
     RunArray from: #(1 2 3 3 3 4 5 5 6 6 6 6 6 6)
    "
! !

! RunArray methodsFor: 'searching' !

findFirst: aBlock
    "find the first element, for which evaluation of the argument, aBlock
     returns true; return its index or 0 if none detected.
     Notice, that not all elements are processed here 
     (the block is only evaluated for each runs first element)."

    | idx| 

    idx <- 1.
    contentsArray notNil ifTrue: [
        contentsArray pairWiseDo: [ :len :val |  
            (aBlock value: val) ifTrue: [^ idx].
            idx <- idx + len.
        ]
    ].
    ^ 0

    "
     (RunArray new 
        add: 1 withOccurrences: 100;
        add: 2 withOccurrences: 100;
        add: 3 withOccurrences: 100;
        add: 4 withOccurrences: 100;
        yourself) findFirst: [ :el |  el == 3] 
    "
!

identityIndexOf: anElement startingAt: start
    "search for identical anElement, return the index or 0 if not found.
     Redefined to prevent a loop over individual accesses via #at:,
     which would be very inefficient."

    |  idx nextRunIdx | 

    contentsArray notNil ifTrue: [

        idx <- 1.
        contentsArray pairWiseDo: [ :len :val | 
            nextRunIdx <- idx + len.
            nextRunIdx > start ifTrue: [
                (anElement == val) ifTrue: [
                    ^ idx max: start
                ]
            ].
            idx <- nextRunIdx.
        ].
    ].
    ^ 0
!

indexOf: anElement startingAt: start
    "search for equal anElement, return the index or 0 if not found.
     Redefined to prevent a loop over individual accesses via #at:,
     which would be very inefficient."

    | idx nextRunIdx| 

    contentsArray notNil ifTrue: [

        idx <- 1.
        contentsArray pairWiseDo: [ :len :val | 
            nextRunIdx <- idx + len.
            nextRunIdx > start ifTrue: [
                (anElement = val) ifTrue: [
                    ^ idx max: start
                ]
            ].
            idx <- nextRunIdx.
        ].
    ].
    ^ 0

    "
     | r| 
     r <- RunArray new. 
     r add: 1 withOccurrences: 100.
     r add: 2 withOccurrences: 100.
     r add: 3 withOccurrences: 100.
     r add: 4 withOccurrences: 100.
     r indexOf: 2 startingAt: 50.  
     r indexOf: 2 startingAt: 100.  
     r indexOf: 2 startingAt: 101.  
     r indexOf: 2 startingAt: 150.  
     r indexOf: 2 startingAt: 200.  
     r indexOf: 2 startingAt: 201.   
     r indexOf: 2 startingAt: 202.   
    "
! !

! RunArray methodsFor: 'testing' !

includes: anElement
    "return true, if the receiver includes an element which is equal
     to the argument, anElement; false otherwise.
     Redefined to prevent the inherited loop over individual accesses via #at:,
     which would be very inefficient."

    contentsArray notNil ifTrue: [
        contentsArray pairWiseDo: [ :len :val | 
            (anElement = val) ifTrue: [
                ^ true
            ].
        ].
    ].
    ^ false
!

includesIdentical: anElement
    "return true, if the receiver includes the argument, anElement; false otherwise.
     Redefined to prevent the inherited loop over individual accesses via #at:,
     which would be very inefficient."

    contentsArray notNil ifTrue: [
        contentsArray pairWiseDo: [ :len :val | 
            (anElement == val) ifTrue: [
                ^ true
            ].
        ].
    ].
    ^ false
! !

