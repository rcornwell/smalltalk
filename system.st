
" Last bits and peices of smalltalk system "

" $Id: system.st,v 1.2 2002/01/29 16:40:38 rich Exp $ "

"
 $Log: system.st,v $
 Revision 1.2  2002/01/29 16:40:38  rich
 Added object dependency methods.

 Revision 1.1  2001/08/29 20:17:07  rich
 Initial revision


"

!

Object subclass: 'System'
       instanceVariableNames: ''
       classVariableNames: ''
       poolDictionaries: ''
       category: 'System'
!

System comment: 'I handle system specific actions.' !

! System class methodsFor: 'System' !

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
	| stream |
	stream <- sourceFiles at: 2.
	stream space.
        stream nextPut: $" .
	stream nextPutAll: ' *** Snapshot *** '.
	Date today printOn: stream.
	stream space.
	Time now printOn: stream.
	stream space.
	stream nextPut: $" .
	stream space.
	stream nextPut: $!! .
	stream nl.
	^ self DoSnapShot: aName
!

newBacktrace 
    | context aCollection |
    aCollection <- OrderedCollection new.
    context <- thisContext.
    [ context notNil ]
	 whileTrue: [ aCollection addLast: context backtraceString.
		      context <- context parentContext ].
    ^aCollection 
!

stackTrace
	<primitive 99>

!

newSourceFile: aName
   " Make a new source file "
   | file fname clist |

   " Build sorted list of objects "
   clist <- Object withAllSubclasses asSortedCollection: 
		[ :a :b | (a name) <= (b name) ].

   " Open new file "
   fname <- aName , '.st'.
   (File name: fname) delete.
   file <- FileStream on: fname mode: 'w'.
   sourceFiles at: 3 put: file.

   " Store all the classes, and update channel "
   clist do: [ :c | c storeOnChannel: 3 ].

   " Switch source files "
   (sourceFiles at: 1) close.
   file close.
   sourceFiles at: 1 put: (FileStream on: fname mode: 'r').
   clist do: [ :c | c adjustSourceChannel: 3 ].

   " Create the new change file "
   (sourceFiles at: 2) close.
   fname <- fname , 'c'.
   (File name: fname) delete.
   sourceFiles at: 2 put: (FileStream on: fname mode: 'a').

   " Last thing is to save a snapshot. "
   fname <- aName , '.sti'.
   ^ System snapShot: fname
! !

! System class methodsFor: 'basic' !

dependenciesAt: anObject
    ^(Smalltalk at: #Dependencies) at: anObject ifAbsent: [ nil ]
! !

Smalltalk at: #Dependencies put: (IdentityDictionary new) !

! Class methodsFor: 'compiler' !

methodsFor: aCategory
      ^ ClassCategoryReader for: self category: aCategory
! !

