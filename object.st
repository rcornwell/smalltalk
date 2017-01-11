" Last bits and peices of smalltalk system "

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

" $Id: object.st,v 1.9 2002/01/29 16:40:38 rich Exp rich $ "

"
 $Log: object.st,v $
 Revision 1.9  2002/01/29 16:40:38  rich
 Added object dependency methods to Object.

 Revision 1.8  2001/08/29 20:16:35  rich
 Added class definitions.
 Moved System class to it's own file.

 Revision 1.7  2001/08/18 16:17:02  rich
 Changed classes and methods to correct categories.
 Added methods to generate a new source file.

 Revision 1.6  2001/08/01 16:42:31  rich
 Fixed bugs in newBacktrace.

 Revision 1.5  2001/07/31 14:09:48  rich
 Code cleanup
 Copied Object, Boolean, True, False class from basic.st

 Revision 1.4  2001/01/17 02:33:16  rich
 Code cleanup
 Rewrote executeLoop.

 Revision 1.3  2000/08/27 17:08:55  rich
 Fixed some typos.
 Added last of code to link in compiler.

 Revision 1.2  2000/02/01 18:09:58  rich
 Changed print to use CharStream class.
 Fixed bugs.
 Added System class.

 Revision 1.1  1999/09/02 15:57:59  rich
 Initial revision

"

!

Object category: 'Basic'. !

! Object methodsFor: 'private'!

DumpObject
	<primitive 95>
! !

! Object methodsFor: 'testing'!

isNil
	^false
!

notNil
	^true
! !

! Object methodsFor: 'comparing'!

== anObject
	"Returns true if the objects are the same."
	<primitive 69>
	^ self primitiveFailed
!

= anObject
	"Returns true if object represent same value."
	^ self == anObject
!

~= anObject
	"Returns true if the objects are not the same."
	^ (self == anObject) not
!

~~ anObject
	"Returns true if the objects don't represent the same thing."
	^ (self = anObject) not
! !

! Object methodsFor: 'testing class membership'!

class
	"Returns class of object"
	<primitive 70>
	^ self primitiveFailed
!


isMemberOf: aClass
	"Returns true if object is a member of aClass"
	^ self class == aClass
!

isKindOf: aClass
	"Tests if object is a class of aClass"
	^ (self isMemberOf: aClass) or:
		[ self class inheritsFrom: aClass ] 

! !

! Object methodsFor: 'accessing' !

basicAt: index
	<primitive 45>
	^ self primitiveFailed
!

basicAt: index put: value
	<primitive 46>
	^ self primitiveFailed
!

basicSize
	<primitive 47>
	^ self primitiveFailed
!

at: index
	^ self basicAt: index
!

at: index put: value
	^ self basicAt: index put: value
!

size
	^self basicSize
!

hash
	"Subclasses should reimplement this, but object number provides a good
	hash for now. "
	<primitive 60>
	^ self primitiveFailed
!

asOop
	"Answer an integer pointer for object."
	<primitive 60>
	^ self primitiveFailed
! !

! Object methodsFor: 'creation' !

basicNew
	^ self class basicNew
!

basicNew: aNumber
	^ self class basicNew: aNumber
! !

! Object methodsFor: 'system primitive'!

become: aObject
	"Make one object become another"
	<primitive 57>
	^ self primitiveFailed
!

instVarAt: index
	"Get the instance variable at index"
	<primitive 58>
	^ self primitiveFailed
!

instVarAt: index put: value
	"Set the instance variable at index"
	<primitive 59>
	^ self primitiveFailed
!

someInstance
	"Return first instance of an object, nil if none"
	<primitive 62>
	^ nil
!

nextInstance
	"Return next instance of object, nil if no more"
	<primitive 63>
	^ nil
!

flushCache
	<primitive 107>
! !

! Object methodsFor: 'message handling'!

preform: aSymbol
	"Sends the reciever the selector aSymbol"
	<primitive 67>
	^ self primitiveFailed
!

preform: aSymbol with: anObject
	"Sends the reciever the selector aSymbol"
	<primitive 67>
	^ self primitiveFailed
!

preform: aSymbol with: anObject with: secondObject
	"Sends the reciever the selector aSymbol"
	<primitive 67>
	^ self primitiveFailed
!

preform: aSymbol with: anObject with: secondObject with: thirdObject
	"Sends the reciever the selector aSymbol"
	<primitive 67>
	^ self primitiveFailed
!

preform: aSymbol withArguments: anArray
	"Sends the reciever the selector aSymbol"
	<primitive 68>
	^ self primitiveFailed
! !

! Object methodsFor: 'private'!

species
    ^self class
!

yourself
    ^self
!

classNameString
        | name |
        name <- self class name.
        name isNil ifTrue: [ name <- self name , ' class' ].
        ^ name
! !

! Object methodsFor: 'copying' !

shallowCopy
	"Make a shallow copy of an object."
	| class newObject |
	class <- self class.
	" Make a new object to hold values"
	class isVariable 
	    ifTrue: [ newObject <- self basicNew: self basicSize ]
	    ifFalse: [ newObject <- self basicNew ].
	" Copy instance variables"
	1 to: class instSize do:
	    [ :i | newObject instVarAt: i put: (self instVarAt: i) ].
	" Copy rest of object if any"
	class isVariable
	     ifTrue: [
		1 to: class basicSize do: 
	    	     [ :i | newObject basicAt: i put: (self basicAt: i) ]
		].
	^ newObject
!

deepCopy
	"Make a true new object"
	| class newObject |
	class <- self class.
	" Make a new object to hold values"
	class isVariable 
	    ifTrue: [ newObject <- self basicNew: self basicSize ]
	    ifFalse: [ newObject <- self basicNew ].
	" Copy instance variables"
	1 to: class instSize do:
	    [ :i | newObject instVarAt: i put: (self instVarAt: i) deepCopy ].
	" Copy rest of object if any"
	class isVariable
	     ifTrue: [
		1 to: class basicSize do: 
	    	     [ :i | newObject basicAt: i put: (self basicAt: i) deepCopy ]
		].
	^ newObject
!

copy
	^self shallowCopy
! !

! Object methodsFor: 'error handling' !

error: aString
	<primitive 94>
	^ self primitiveFailed
!

doesNotUnderstand: aMessage
	^ self error:  (self class name) , ' does not understand #',
		aMessage selector asString.
!

primitiveFailed
	^ self error: 'Primitive Failed'
!

shouldNotImpliment
	^ self error: 'Should not impliment'
!

subclassResonsibility
	^ self error: 'Subclass Responsablity'
!

interpStackFault
	^ self error: 'Attempt to access outside stack'
!

mustBeBoolean
	^ self error: 'ifTrue: or ifFalse: require boolean value'
! !

! Object methodsFor: 'printing' !

printString
	"Return a string representation of self"
	| aStream |
	aStream <- WriteStream on: (String new: 0).
	self printOn: aStream.
	^ aStream contents
!

printOn: aStream
	"Print the objects class name."
	| name first |
	name <- self classNameString.
	first <- (name at: 1) isVowel ifTrue: [ 'an ' ] ifFalse: [ 'a ' ]. 
	aStream nextPutAll: first.
	aStream	nextPutAll: name
!

print
	stdout nextPutAll: (self printString).
	stdout nl.
	^ self
!

storeString
	"Return a string representation of self"
	| aStream |
	aStream <- WriteStream on: (String new: 0).
	self storeOn: aStream.
	^ aStream contents
!

storeOn: aStream
	"Store the object onto the stream."
	| class semi |
	class <- self class.
	aStream nextPut: $(.
	aStream nextPutAll: self classNameString.
	class isVariable 
	    ifTrue: [ aStream nextPutAll: ' basicNew: '.
		      self basicSize printOn: aStream ]
	    ifFalse: [ aStream nextPutAll: ' basicNew' ].
	semi <- false.
	1 to: class instSize do:
	    [ :i | aStream nextPutAll: ' instVarAt: '.
		   i printOn: aStream.
		   aStream nextPutAll: ' put: '.
		   (self instVarAt: i) storeOn: aStream.
		   aStream nextPut: $;.
		   semi <- true ].
	class isVariable ifTrue:
	    [ 1 to: self basicSize do:
		[ :i | aStream nextPutAll: ' basicAt: '.
		   i printOn: aStream.
		   aStream nextPutAll: ' put: '.
		   (self basicAt: i) storeOn: aStream.
		   aStream nextPut: $;.
		   semi <- true ]
	     ].
	semi ifTrue: [ aStream nextPutAll: ' self' ].
	aStream nextPut: $)
		   
! !

! Object methodsFor: 'shortcut' !

-> anObject
	^ Association key: self value: anObject
! !

! Object methodsFor: 'dependents access'  !

addDependent: anObject
    | dependencies |
    dependencies <- System dependenciesAt: self.
    dependencies isNil ifTrue:
    	[ dependencies <- Set new.
	  (Smalltalk at: #Dependencies) at: self put: dependencies ].
    dependencies add: anObject
!

removeDependent: anObject
    | dependencies |
    dependencies <- System dependenciesAt: self.
    dependencies notNil ifTrue:
    	[ dependencies remove: anObject ifAbsent: [] ]
!

dependents
    | dependencies |
    dependencies <- System dependenciesAt: self.
    dependencies isNil ifTrue: [ dependencies <- Set new ].
    ^dependencies asOrderedCollection
!

release
    " +++ I'm not sure that this is the right thing to do here; the book is
      so vague... "
    (Smalltalk at: #Dependencies) removeKey: self
! !

! Object methodsFor: 'change and update' !

changed
    self changed: self
!

changed: aParameter
    | dependencies |
    dependencies <- System dependenciesAt: self.
    dependencies notNil ifTrue:
    	[ dependencies do:
	    [ :dependent | dependent update: aParameter ] ]
!

update: aParameter
    "Default behavior is to do nothing"
!

broadcast: aSymbol
    | dependencies |
    dependencies <- System dependenciesAt: self.
    dependencies notNil ifTrue:
    	[ dependencies do:
	    [ :dependent | dependent perform: aSymbol ] ]
!

broadcast: aSymbol with: anObject
    | dependencies |
    dependencies <- System dependenciesAt: self.
    dependencies notNil ifTrue:
    	[ dependencies do:
	    [ :dependent | dependent perform: aSymbol with: anObject ] ]
! !

Object subclass: 'Message'
       instanceVariableNames: 'args selector'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'System-Execution' !

Message comment: 'I am generated by the system when a send fails.' !

! Message methodsFor: 'access' !

selector
	^selector
! !

Object subclass: 'Undefined'
       instanceVariableNames: ''
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Basic' !

Undefined comment: 'I represent objects that don''t exist.' !

! Undefined methodsFor: 'testing'!

isNil
	^true
!

notNil
	^false
! !

! Undefined methodsFor: 'printing' !

printString
	"Return a string representation of self"
	^ 'nil'
!

printOn: aStream
	"Print the objects class name."
	aStream nextPutAll: 'nil'
!

storeString
	"Return a string representation of self"
	^ 'nil'
!

storeOn: aStream
	"Store the object onto the stream."
	aStream nextPutAll: 'nil'.
! !

! Undefined methodsFor: 'class hierarchy' !

subclass: classNameString instanceVariableNames: stringInstVarNames
       classVariableNames: stringClassVarNames
       poolDictionaries: stringPoolNames
       category: categoryNameString
	" For right now we can't redefine object "
	^ Object
! !

Object subclass: 'Boolean'
       instanceVariableNames: ''
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Basic' !

! Boolean methodsFor: 'copying'!

deepCopy
	^ self
!
	
shallowCopy
	^ self
! !

Boolean subclass: 'True'
       instanceVariableNames: ''
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Basic' !

True comment: 'I represent True value objects. There is only one of me in the
whole system. ' !

! True class methodsFor: 'creating'!

new
	^ true
! !

! True methodsFor: 'logical pperations'!

& aBoolean
	^ aBoolean
!

| aBoolean
	^ true
!

not 
	^ false
!

eqv: aBoolean
	^ aBoolean 
!

xor: aBoolean
	^ aBoolean not
! !

! True methodsFor: 'control structures' !

and: aBlock
	^ aBlock value
!

or: aBlock
	^ true
!

ifTrue: trueBlock ifFalse: falseBlock
	^ trueBlock value
!

ifFalse: falseBlock ifTrue: trueBlock
	^ trueBlock value
!

ifTrue: trueBlock
	^ trueBlock value
!

ifFalse: falseBlock
	^ nil
! !

Boolean subclass: 'False'
       instanceVariableNames: ''
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Basic' !

False comment: 'I represent False value objects. There is only one of me in the
whole system. ' !


! False class methodsFor: 'creating'!

new
	^ false
! !

! False methodsFor: 'logical operations'!

& aBoolean
	^ false
!

| aBoolean
	^ aBoolean
!

not 
	^ true
!

eqv: aBoolean
	^ aBoolean not
!

xor: aBoolean
	^ aBoolean 
! !

! False methodsFor: 'control structures' !

and: aBlock
	^ false
!

or: aBlock
	^ aBlock value
!

ifTrue: trueBlock ifFalse: falseBlock
	^ falseBlock value
!

ifFalse: falseBlock ifTrue: trueBlock
	^ falseBlock value
!

ifTrue: trueBlock
	^ nil
!

ifFalse: falseBlock
	^ falseBlock value
! !

