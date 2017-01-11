" Last piece of bootstrap code. "

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

