" Last piece of bootstrap code. "

" $Id: $ "

"
 $Log: $

"

!
| n array |
(Smalltalk at: #loading ifAbsent: [nil]) isNil
  ifTrue: [
	" First time through, define and reload self with native compiler."

	" Set flag so we don't loop "
	Smalltalk at: #loading put: true.

	" next, set up sourceFiles array "
	n <- initSourceFile at: 1.
	array <- Array new: 4.
	array at: 1 put: (FileStream on: n mode: 'r').
	array at: 2 put: (FileStream on: (n, 'c') mode: 'a').
	Smalltalk at: #sourceFiles put: array.

	" Log our progress "
	stderr nextPutAll: 'Base Loaded'.
	stderr nl.

	" Reload full system now"
	FileStream fileIn: 'smalltalk.st'. 

	" Remove flag... we don't need it anymore "
	Smalltalk removeKey: #loading ifAbsent: [nil].

	" Now save an image "
	stderr nextPutAll: 'Saving image'.
	stderr nl.
	(System snapShot: 'smalltalk.sti')
		 ifTrue: [ System quit ]
		" When we come back after reload, run execute loop. "
		 ifFalse: [ stdin executeLoop ]
 ]

!

