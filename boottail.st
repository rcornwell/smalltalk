" Last piece of bootstrap code. "

" $Id: boottail.st,v 1.3 2001/08/29 20:16:34 rich Exp rich $ "

"
 $Log: boottail.st,v $
 Revision 1.3  2001/08/29 20:16:34  rich
 Changed source file name to read in.

 Revision 1.2  2001/08/18 16:17:00  rich
 Clear changes file before we start reloading system.
 Build a new source file after we have completed system load.

 Revision 1.1  2001/07/31 14:10:39  rich
 Initial revision


"

!
| n array |
	" First time through, define and reload self with native compiler."

	" Set flag so we don't loop "
	Smalltalk at: #loading put: true.

	" next, set up sourceFiles array "
	n <- initSourceFile name.
	(File name: (n , 'c')) delete.
	array <- Array new: 4.
	array at: 1 put: (FileStream on: n mode: 'r').
	array at: 2 put: (FileStream on: (n, 'c') mode: 'a').
	Smalltalk at: #sourceFiles put: array.

	" Log our progress "
	stderr nextPutAll: 'Base Loaded'.
	stderr nl.

	" Reload full system now"
	FileStream fileIn: 'source.st'. 

	" Remove flag... we don't need it anymore "
	Smalltalk removeKey: #loading ifAbsent: [nil].


	" Now save an image "
	stderr nextPutAll: 'Saving system'.
	stderr nl.
	(System newSourceFile: 'smalltalk')
		 ifTrue: [ System quit ]
		" When we come back after reload, run execute loop. "
		 ifFalse: [
		 "    [ (Smalltalk at: #DisplayScreen) preform: #initSystem
		     ] forkAt: Processor userSchedulingPriority."
		     stdin executeLoop
		     " Not reached. "
		 ]

!

