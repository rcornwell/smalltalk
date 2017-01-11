" Methods for Class misc extra classes"

" Copyright 1999-2017 Richard P. Cornwell.
 
  This program is free software; you can redistribute it and/or modify it
  under the terms of the the Artistic License (2.0). You may obtain a copy
  of the full license at:
 
  http://www.perlfoundation.org/artistic_license_2_0
 
  Any use, modification, and distribution of the Standard or Modified
  Versions is governed by this Artistic License. By using, modifying or
  distributing the Package, you accept this license. Do not use, modify, or
  distribute the Package, if you do not accept this license.
 
  If your Modified Version has been derived from a Modified Version made by
  someone other than you, you are nevertheless required to ensure that your
  Modified Version complies with the requirements of this license.
 
  This license does not grant you the right to use any trademark, service
  mark, tradename, or logo of the Copyright Holder.
 
  Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
  AND CONTRIBUTORS 'AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
  THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
  PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
  YOUR LOCAL LAW.  UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
  CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
  CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. "

" $Id: misc.st,v 1.5 2001/08/18 16:17:01 rich Exp $ "

"
 $Log: misc.st,v $
 Revision 1.5  2001/08/18 16:17:01  rich
 Fixed category of class.

 Revision 1.4  2001/07/31 14:09:48  rich
 Code cleanup

 Revision 1.3  2001/01/07 15:47:21  rich
 Code cleanup

 Revision 1.2  2000/02/01 18:09:56  rich
 Moved Date and Time collection to magnitude.

 Revision 1.1  1999/09/02 15:57:59  rich
 Initial revision

"

Stream subclass: 'Random'
       instanceVariableNames: 'seed'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Streaming'
!

Random comment: 
'My instances are generator streams that produce random numbers, which are 
floating point values between 0 and 1.'!

! Random class methodsFor: 'instance creation'!

new
    ^self basicNew setSeed
! !

! Random methodsFor: 'testing'!

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


! Random methodsFor: 'basic'!

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

! Random methodsFor: 'private'!

setSeed
    seed <- Time secondClock
! !

