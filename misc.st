" Methods for Class misc extra classes"

" $Id: misc.st,v 1.1 1999/09/02 15:57:59 rich Exp rich $ "

"
 $Log: misc.st,v $
 Revision 1.1  1999/09/02 15:57:59  rich
 Initial revision

"

Stream subclass: 'Random'
       instanceVariableNames: 'seed'
       classVariableNames: ''
       poolDictionaries: ''
       category: nil
!

Random comment: 
'My instances are generator streams that produce random numbers, which are 
floating point values between 0 and 1.'!

!Random class methodsFor: 'instance creation'!

new
    ^self basicNew setSeed
! !

!Random methodsFor: 'testing'!

chiSquare
    "returns on Sun3 93.40000000000009"
    ^self chiSquare: 1000 range: 100
!

chiSquare: n range: r
    | f t s |
    s <- 1234567.
    f <- Array new: r + 1.
    1 to: r + 1 do: [ :i | f at: i put: 0 ].
    n timesRepeat:
        [ s <- (s * 31415821) + 1 bitAnd: 16r3FFFFFFF.
          t <- s \\ r.
          f at: t + 1 put: (f at: t + 1) + 1 ].
    t <- 0.
    1 to: r do: [ :i | t <- t + (f at: i) squared ].
    ^r asFloat * t / n - n

! !


!Random methodsFor: 'basic'!

atEnd
    ^false
!

next
    | value |
    "From Sedgewick's 'Algorithms', based on Lehmer's method"
    seed <- (seed * 31415821) + 1 bitAnd: 16r3FFFFFFF.
    ^seed / 16r3FFFFFFF.0
!

nextPut: value
    self shouldNotImplement
!

next: anInteger
    | collection |
    collection <- OrderedCollection new.
    anInteger timesRepeat: [ collection add: self next ]. 
    ^collection
!

nextMatchFor: aNumber
    ^self next = aNumber
! !

!Random methodsFor: 'private'!

setSeed
    seed <- Time secondClock
! !
