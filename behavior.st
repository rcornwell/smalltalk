" Methods for Behavior and Class"

" $Id: behavior.st,v 1.2 2000/02/01 18:09:45 rich Exp rich $ "
        
"
 $Log: behavior.st,v $
 Revision 1.2  2000/02/01 18:09:45  rich
 Completed missing routines.
 Hooks to native compiler.

 Revision 1.1  1999/09/02 15:57:59  rich
 Initial revision

"
!

Object subclass: 'ClassCategoryReader' instanceVariableNames: 'myClass myCategory'
       classVariableNames: '' poolDictionaries: '' category: nil
!

! ClassCategoryReader class methodsFor: 'creation' !

for: aClass category: aCategory
     ^ self new for: aClass category: aCategory
! !

! ClassCategoryReader methodsFor: 'Basic' !

for: aClass category: aCategory
    myClass <- aClass.
    myCategory <- aCategory asSymbol.
!

fileInFrom: aStream
   | aString |
   [ aStream atEnd or: [(aString <- aStream nextchunk) isEmpty ]] whileFalse:
	[ Compiler compile: aString forClass: myClass classified: myCategory ].
! !

MethodInfo comment: 'I represent information about compiled methods' !

! MethodInfo methodsFor: 'Accessing' !

sourceFile
	^ sourceFile
!

sourcePos
	^ sourcePos
!

category
	^ category
!

sourceCode
	| stream |
	stream <- sourceFiles at: sourceFile.
	stream <- stream copy.
	stream position: sourcePos.
	^ stream nextChunk.
! !

! MethodInfo methodsFor: 'Setting' !

sourceFile: aInteger
	^ sourceFile <- aInteger
!

sourcePos: aInteger
	^ sourcePos <- aInteger
!

category: aSymbol
	^ category <- aSymbol
!

sourceCode: aString
	| stream |
	" Save the source code at end of change file. "
	sourceFile <- 2.
	stream <- sourceFiles at: sourceFile.
	stream isNil ifFalse: [
		stream <- stream deepcopy.
		sourcePos <- stream setToEnd.
		stream nextChunkPut: aString.
		stream nextChunkPut: ''.
	].
!

sourceCode: aString forCategory: aCategory
	| stream |
	" Save the source code at end of change file. "
	sourceFile <- 2.
	stream <- sourceFiles at: sourceFile.
	stream isNil ifFalse: [
		stream <- stream deepcopy.
		sourcePos <- stream setToEnd.
		stream nextChunkPut: aString.
		stream nextChunkPut: ''.
	].
	category <- aCategory.
!

sourceFile: aFile sourcePos: position category: aCategory
	sourceFile <- aFile.
	sourcePos <- position.
	category <- aCategory
! !

! MethodInfo class methodsFor: 'creations' !

sourceFile: aFile sourcePos: position category: aCategory
	^ self new sourceFile: aFile sourcePos: position category: aCategory
!

sourceCode: aString forCategory: aCategory
	^ self new sourceCode: aString forCategory: aCategory
! !

! CompiledMethod methodsFor: 'source access' !

getSource
	^ description sourceCode.
! !

! Behavior methodsFor: 'Creating Method Dictionary'!

methodDictionary: aDictionary
	" Set the method dictionary to a new dictionary. "
	^ methoddict <- aDictionary

!

addSelector: selector withMethod: compiledMethod
	"Adds the selector with compiled method to the class dictionary."
	methoddict at: selector put: compiledMethod.
!

removeSelector: selector
	"Removes the selector from the method."
	methoddict remove: selector.
! !

! Behavior methodsFor: 'Instance protocol'!

superclass: aClass
	^ superclass <- aClass
!

addSubclass: aClass
        "Adds a subclass to set of subclasses"
	subclasses isNil ifTrue:
		[ subclasses <- Set new ].
        subclasses add: aClass
!

removeSubclass: aClass
        "Remove a class from list of classes subclasses."
        subclasses remove: aClass
! !

! Behavior methodsFor: 'Accessing method dictionary'!

selectors
	| sels |
	sels <- Set new.
	methoddict keysDo: [ :key | sels add: key ].
	^ sels
!

allSelectors
	| sels cl |
	sels <- self selectors.
	cl <- self superclass.
	[ cl notNil ] whileTrue: [
		(self selectors) keysDo: [ :key | sels add: key ].
		cl <- cl superclass ].
	^ sels
!

compiledMethodAt: selector
	^ methoddict at: selector ifAbsent: [ nil ]
! !

! Behavior methodsFor: 'testing method dictionary' !

hasMethods
	^ methoddict size ~= 0
!

includesSelector: selector
	methoddict isNil ifTrue: [ ^ false ].
	^ methoddict includesKey: selector
!

canUnderstand: selector
	(methoddict includesKey: selector) ifTrue: [ ^ true ].
	superclass isNil ifTrue: [ ^ false ].
	^ superclass canUnderstand: selector
!

whichClassIncludesSelector: selector
	(methoddict includesKey: selector) ifTrue: [ ^ self ].
	superclass isNil ifTrue: [ ^ nil ].
	^ superclass whichClassIncludesSelector: selector
! !	

! Behavior methodsFor: 'Accessing class heirarchy'!

allSubclasses
	"Return a set of all subclasses"
	| subs allsubs |
	allsubs <- Set new.
	self subclasses do: [ :subclass | 
		allsubs add: subclass.
		subclass allSubclasses do: [ :subsubc | allsubs add: subsubc]
	].
	^ allsubs
!

withAllSubclasses
	" Return all subclasses include ourselfs"
	| subs |
	subs <- self allSubclasses.
	subs add: self.
	^ subs
!

subclasses
        "Return a set of immediate subclasses"
        ^ subclasses
!

superclass
	^superclass
!

allSuperclasses
	| classes cl |
	classes <- OrderedCollection new.
	cl <- self superclass.
	[ cl notNil ] whileTrue: [
		 classes addLast: cl. 
		cl <- cl superclass ].
	^ classes
! !

! Behavior methodsFor: 'Testing the form of instances' !

instSize
	^ flags // 8
!

isPointer
	^ ( flags bitAnd: 1 ) ~= 0
!

isBits
	^ ( flags bitAnd: 1 ) == 0
!

isBytes
	^ ( flags bitAnd: 2) ~= 0
!

isWords
	^ ( flags bitAnd: 2) == 0
!

isFixed
	^ ( flags bitAnd: 4) == 0
!

isVariable
	^ ( flags bitAnd: 4) ~= 0
! !

! Class methodsFor: 'Accessing'!

name
	^ name
!

instanceCount
	| count inst |
	count <- 0.
	inst <- self someInstance.
	inst isNil ifTrue: [ ^ count ].
	[ (inst <- inst nextInstance) notNil ] whileTrue: [ count <- count + 1].
	^ count
!

instVarNames
	vars isNil ifTrue: [ vars <- Array new: 0 ].
	^ vars
!

allInstVarNames
    | svars newarray |
    superclass isNil ifTrue: [ ^ Array new: 0 ].
    svars <- superclass allInstVarNames.
    newarray <- WriteStream on: (Array new: 0).
    newarray nextPutAll: svars.
    newarray nextPutAll: vars.
    ^ newarray contents
!

classVarNames
    | names |
    names <- Set new.
    classvars isNil ifTrue: [ ^ names ].
    classvars keysDo: [ :key | names add: key ].
    ^ names
!

allClassVarNames
    | names |
    superclass isNil ifTrue: [ ^ Set new ].
    names <- self classVarNames.
    superclass allClassVarNames do: [ :n | names add: n ].
    ^ names
!

sharedPools
    | set |
    set <- Set new.
    pool isNil ifTrue: [ ^ set ].
    pool keysDo: [ :n | set add: n ].
    ^ set
!

allSharedPools
    | names sclass |
    superclass isNil ifTrue: [ ^ Set new ].
    names <- Set new.
    self sharedPools do: [ :n | names add: n ].
    superclass allSharedPools do: [ :n | names add: n ].
    ^ names
!
    
comment
	^ comment
!

category
	^ category
! !

! Class methodsFor: 'printing' !

poolVariableString
	| stream |
	stream <- WriteStream on: (String new: 0).
	self sharedPools do: [ :n |
		stream nextPutAll: n asString.  stream space.
	].
	" Remove trailing blank "
	stream isEmpty ifFalse: [ stream skip: -1 ].
	^ stream contents
!

classVariableString
	| stream |
	stream <- WriteStream on: (String new: 0).
	self classVarNames do: [ :n |
		stream nextPutAll: n asString.  stream space.
	].
	" Remove trailing blank "
	stream isEmpty ifFalse: [ stream skip: -1 ].
	^ stream contents
!

instanceVariableString
	| stream |
	stream <- WriteStream on: (String new: 0).
	self instVarNames do: [ :n |
		stream nextPutAll: n asString.  stream space.
	].
	" Remove trailing blank "
	stream isEmpty ifFalse: [ stream skip: -1 ].
	^ stream contents
! !

! Class methodsFor: 'Modification' !

instVarNames: aString
    | isize cl |
    vars <- self StringasArray: aString.
    isize <- vars size.
    cl <- self superclass.
    cl notNil ifTrue: [ isize <- cl instSize + isize ].
    flags isNil ifTrue: [ flags <- isize * 8 ]
                ifFalse: [ flags <- (isize * 8) + (flags bitAnd: 7)].
    ^ vars
!

addInstVarName: aString
    | var |
    " First check if it already exists "
    vars do: [ :v | v = aString ifTrue: [ ^self]].
    " Build new array one size bigger "
    var <- Array new: (vars size + 1).
    1 to: vars size do: [ :i | var at: i put: (vars at: i)].
    var at: (var size) put: aString.
    vars <- var.
    flags <- flags + 8.
!

removeInstVarName: aString
    vars do: [ :v | v = aString ifTrue: [ vars at: v put: nil. ^ self ]].
    self error: 'Instance ', aString, ' not found in class'.
!

classVarNames: aString
    | names newdict |
    newdict <- Dictionary new.
    classvars isNil ifTrue: [ classvars <- Dictionary new].
    names <- self StringasArray: aString.
    names do: [ :n |
	newdict add: (classvars associationAt: (n asSymbol) ifAbsent:
			[ Association key: (n asSymbol) value: nil ])].
    classvars <- newdict.
    ^ newdict
!

addClassVarName: aString
    classvars associationAt: aString asSymbol ifAbsent:
			[ classvars at: aString asSymbol put: nil ].
!

removeClassVarName: aString
    classvars removeKey: name asSymbol.
!

sharedPool: aString
    | names |
    pool <- Dictionary new.
    names <- self StringasArray: aString.
    names do: [ :n | pool at: n asString put: (Smalltalk at: n asString)].
    ^ pool
!

addSharedPool: aString
    | n |
    n <- aString asSymbol.
    pool keysdo: [ :key | key == n ifTrue: [
		self error: aString, ' already exists in pool'. ^ self ]].
    pool at: n put: (Smalltalk at: n).
!

removeSharedPool: aString
    pool removeKey: name.
!

classPool
    ^ classvars
!

" Place holder method "
initialize
    ^ self
!

comment: aString
	^ comment <- aString
!

category: aString
	^ category <- aString
!

name: aString
	^ name <- aString
!

instFlags: variableBoolean
	words: wordBoolean
	pointers: pointerBoolean
	| temp |
	flags isNil ifTrue: [ temp <- 0 ]
		    ifFalse: [ temp <- flags bitAnd: ( 7 negated)].
	pointerBoolean 
	    ifTrue: [ temp <- temp bitOr: 1 ]
	    ifFalse: [ wordBoolean ifFalse: [ temp <- temp bitOr: 2 ]].
	variableBoolean ifTrue: [ temp <- temp bitOr: 4 ].
	^ flags <- temp
! !

! Class methodsFor: 'Testing class hierarchy' !

inheritsFrom: aClass
	superclass == aClass ifTrue: [ ^ true ].
	superclass isNil ifTrue: [ ^ false ].
	^ superclass inheritsFrom: aClass
!

kindOfSubclass
	| string |
	string <- WriteStream on: (String new: 0).
	self isVariable ifTrue: [ string nextPutAll: 'Variable' ].
	self isBytes ifTrue: [ string nextPutAll: 'Byte' ]
	  ifFalse: [ self isWords ifTrue: [ string nextPutAll: 'Word' ]].
	string nextPutAll: 'SubClass:'.
	string <- string contents.
	string at: 1 put: ((string at: 1) asLowercase ).
	^ string
! !

! Class methodsFor: 'Enumeration' !

allSubclassesDo: aBlock
 	^ self allSubclasses do: aBlock
!

allSuperclassesDo: aBlock
	^ self allSuperclasses do: aBlock
!

allInstancesDo: aBlock
	| inst |
	inst <- self someInstance.
	inst notNil ifTrue: [
		aBlock value: inst.
		[ (inst <- inst nextInstance) notNil ] whileTrue:
			 [ aBlock value: inst]].
!	

allSubinstancesDo: aBlock
	self allSubclasses do: [ :sub | sub allInstancesDo: aBlock ].
!

selectSubclasses: aBlock
	| set |
	set <- Set new.
	self allSubclasses do: [ :sub |
		(aBlock value: sub) ifTrue: [ set add: sub ] ].
	^ set
!

selectSuperclasses: aBlock
	| set |
	set <- Set new.
	self allSuperclasses do: [ :sub |
		(aBlock value: sub) ifTrue: [ set add: sub ] ].
	^ set
! !

! Class methodsFor: 'organization of messages' !

removeCategory: aString
      | sels |
       methcats isNil ifFalse: [
	   sels <- methcats at: aString asSymbol ifAbsent: [ nil ].
	   sels isNil ifFalse: [
		sels do: [ :s | self removeSelector: s ].
	    ].
	    methcats removeKey: aString asSymbol ifAbsent: [ nil ].
       ]
!

whichCategoryIncludesSelector: selector
	| meth info |
	meth <- self compiledMethodAt: selector.
	meth isNil ifFalse: [
	   info <- self description.
	   info isNil ifFalse: [ ^ info catagory ]
	].
	^ nil
!

addSelector: aSelector withMethod: meth classified: aCategory
	| info set oldcat |
	self addSelector: aSelector withMethod: meth.
	aCategory isNil ifFalse: [
	    info <- self description.
	    info isNil ifFalse: [
		  info <- MethodInfo new.
		  meth description: info ].
	    info category: aCategory asSymbol.
	    " Remove it from old category "
	    (oldcat <- self whichCategoryIncludesSelector: aSelector) isNil
		    ifFalse: [ (methcats at: aCategory) remove: aSelector ].
	    " Create dictionary if one does not exist "
	    methcats isNil ifTrue: [ methcats <- Dictionary new ].
	    " Add selector into category "
	    set <- methcats at: aCategory asSymbol ifAbsent:
		   [ set <- Set new. methcats at: aCategory asSymbol put: set ].
	    set add: aSelector.
	]
!
	

copy: aSelector from: aClass
	| meth info |
	meth <- aClass compiledMethodAt: aSelector.
	meth isNil ifFalse: [
	   info <- self description.
	   info isNil ifFalse: [ info <- info category ].
	   self addSelector: aSelector withMethod: meth classified: info.
	].
!

copy: aSelector from: aClass classified: categoryName
	| meth info |
	meth <- aClass compiledMethodAt: aSelector.
	meth isNil ifFalse: [
	   meth <- meth deepcopy.
	   info <- self description.
	   info isNil ifTrue: [
		 info <- MethodInfo new.
		 meth description: info
	   ].
	   self addSelector: aSelector withMethod: meth classified: info.
	].	
!

copyAll: arrayOfSelectors from: aClass
	arrayOfSelectors do: [ :s | self copy: s from: aClass ]
!

copyAll: arrayOfSelectors from: aClass classified: categoryName
	arrayOfSelectors do: [ :s |
		 self copy: s from: aClass classified: categoryName]
!

copyCategory: categoryName from: aClass
	methcats isNil ifTrue: [ ^ self ].
	(methcats at: categoryName asSymbol ifAbsent: [ ^ self ])
	      do: [ :s | self copy: s from: aClass ]
!

copyCategory: categoryName from: aClass classified: newCategoryName
	methcats isNil ifTrue: [ ^ self ].
	(methcats at: categoryName asSymbol ifAbsent: [ ^ self ])
	     do: [ :s | self copy: s from: aClass classified: newCategoryName ]
! !

! Class methodsFor: 'Instance Creation'!

subclass: classNameString instanceVariableNames: stringInstVarNames
       classVariableNames: stringClassVarNames
       poolDictionaries: stringPoolNames
       category: categoryNameString
	| newMeta |
	newMeta <- self metaclassFor: classNameString.
	^ newMeta name: classNameString
	          enviorment: Smalltalk
	          subclassOf: self
	          instanceVariableNames: stringInstVarNames
	          variable: false
	          words: false
	          pointers: true
	          classVariableNames: stringClassVarNames
	          poolDictionaries: stringPoolNames
	          category: categoryNameString
		  comment: nil
		  changed: nil
!

variableSubclass: classNameString instanceVariableNames: stringInstVarNames
       classVariableNames: stringClassVarNames
       poolDictionaries: stringPoolNames
       category: categoryNameString
	| newMeta |
	newMeta <- self metaclassFor: classNameString.
	^ newMeta name: classNameString
	          enviorment: Smalltalk
	          subclassOf: self
	          instanceVariableNames: stringInstVarNames
	          variable: true
	          words: false
	          pointers: true
	          classVariableNames: stringClassVarNames
	          poolDictionaries: stringPoolNames
	          category: categoryNameString
		  comment: nil
		  changed: nil
!

variableByteSubclass: classNameString instanceVariableNames: stringInstVarNames
       classVariableNames: stringClassVarNames
       poolDictionaries: stringPoolNames
       category: categoryNameString
	| newMeta |
	newMeta <- self metaclassFor: classNameString.
	^ newMeta name: classNameString
	          enviorment: Smalltalk
	          subclassOf: self
	          instanceVariableNames: stringInstVarNames
	          variable: true
	          words: false
	          pointers: false
	          classVariableNames: stringClassVarNames
	          poolDictionaries: stringPoolNames
	          category: categoryNameString
		  comment: nil
		  changed: nil
!

variableWordSubclass: classNameString instanceVariableNames: stringInstVarNames
       classVariableNames: stringClassVarNames
       poolDictionaries: stringPoolNames
       category: categoryNameString
	| newMeta |
	newMeta <- self metaclassFor: classNameString.
	^ newMeta name: classNameString
	          enviorment: Smalltalk
	          subclassOf: self
	          instanceVariableNames: stringInstVarNames
	          variable: true
	          words: true
	          pointers: false
	          classVariableNames: stringClassVarNames
	          poolDictionaries: stringPoolNames
	          category: categoryNameString
		  comment: nil
		  changed: nil
!

byteSubclass: classNameString instanceVariableNames: stringInstVarNames
       classVariableNames: stringClassVarNames
       poolDictionaries: stringPoolNames
       category: categoryNameString
	| newMeta |
	newMeta <- self metaclassFor: classNameString.
	^ newMeta name: classNameString
	          enviorment: Smalltalk
	          subclassOf: self
	          instanceVariableNames: stringInstVarNames
	          variable: false
	          words: false
	          pointers: false
	          classVariableNames: stringClassVarNames
	          poolDictionaries: stringPoolNames
	          category: categoryNameString
		  comment: nil
		  changed: nil
!

wordSubclass: classNameString instanceVariableNames: stringInstVarNames
       classVariableNames: stringClassVarNames
       poolDictionaries: stringPoolNames
       category: categoryNameString
	| newMeta |
	newMeta <- self metaclassFor: classNameString.
	^ newMeta name: classNameString
	          enviorment: Smalltalk
	          subclassOf: self
	          instanceVariableNames: stringInstVarNames
	          variable: false
	          words: true
	          pointers: false
	          classVariableNames: stringClassVarNames
	          poolDictionaries: stringPoolNames
	          category: categoryNameString
		  comment: nil
		  changed: nil
! !

! Class methodsFor: 'Private'!

metaclassFor: classNameString
	| aClass |
	aClass <- Smalltalk at: classNameString asSymbol ifAbsent: [ nil ].
	aClass isNil ifTrue:
		[ ^ MetaClass subclassOf: self class ].
	^ aClass class
!

StringasArray: aString
    | str collect stream c array |
    stream <- ReadStream on: aString.
    collect <- OrderedCollection new.
    str <- WriteStream on: (String new: 0).
   " Scan string "
    [ stream atEnd ] whileFalse: [
	c <- stream next.
	c = $  ifTrue: [
		str isEmpty ifFalse: [
		    collect add: (str contents).
    		    str <- WriteStream on: (String new: 0).
		].
	] ifFalse: [ str nextPut: c ]
    ].
   " Get last item if there is one "
    str isEmpty ifFalse: [
        collect add: (str contents).
        str <- WriteStream on: (String new: 0).
    ].
   " Convert it to a array "
    array <- Array new: (collect size).
    1 to: (collect size) do: [ :i | array at: i put: (collect at: i)].
    ^array
! !

! MetaClass class methodsFor: 'Creation'!

subclassOf: aClass
	| newMeta |
	newMeta <- self new.
	newMeta superclass: aClass.
	^ newMeta
! !

! MetaClass methodsFor: 'Accesss' !

instanceClass
	^ instanceClass
!

instanceClass: aClass
	^ instanceClass <- aClass
! !

! MetaClass methodsFor: 'Basic'!

name: newName
	enviorment: aSystemDictionary
	subclassOf: superClass
	instanceVariableNames: stringOfInstVarNames
	variable: variableBoolean
	words: wordsBoolean
	pointers: pointersBoolean
	classVariableNames: stringOfClassVarNames
	poolDictionaries: stringOfPoolNames
	category: categoryName
	comment: commentString
	changed: changed
	| aClass className |

	className <- newName asSymbol.
	aClass <- aSystemDictionary at: className ifAbsent: [ nil ].
	aClass isNil ifTrue: [
		^ self  newMeta: newName
			enviorment: aSystemDictionary
			subclassOf: superClass
			instanceVariableNames: stringOfInstVarNames
			variable: variableBoolean
			words: wordsBoolean
			pointers: pointersBoolean
			classVariableNames: stringOfClassVarNames
			poolDictionaries: stringOfPoolNames
			category: categoryName
			comment: commentString
			changed: changed
	].
	" Don't modify existing class too much "
	name <- newName.
	instanceClass <- aClass.
	" Update subclass chain "
	aClass superclass notNil ifTrue: [
		aClass superclass ~= superClass ifTrue:
		      [ aClass superclass removeSubclass: aClass
			superClass addSubclass: aClass ].
	].
	aClass superclass: superClass.
	superClass notNil
	    ifTrue: [ aClass class superclass: superClass class ].
	aClass name: newName.
	aClass instFlags: variableBoolean words: wordsBoolean
		pointers: pointersBoolean.
	aClass instVarNames: stringOfInstVarNames.
	classvars <- aClass classVarNames: stringOfClassVarNames.
	aClass sharedPool: stringOfPoolNames.
	aClass category: categoryName.
	aClass comment: commentString.
	^ aClass
!
				
newMeta: newName
	enviorment: aSystemDictionary
	subclassOf: superClass
	instanceVariableNames: stringOfInstVarNames
	variable: variableBoolean
	words: wordsBoolean
	pointers: pointersBoolean
	classVariableNames: stringOfClassVarNames
	poolDictionaries: stringOfPoolNames
	category: categoryName
	comment: commentString
	changed: changed
	| aClass |
	" Fill in the metaclass first "
	vars <- Class instVarNames.
	" Set instance size before we go too far "
        flags <- (Class instSize * 8) + 1.
	name <- newName.
	aClass <- self new.
	instanceClass <- aClass.
	" Now fill in the class "
	aClass superclass: superClass.
	aClass name: newName.
	aClass instFlags: variableBoolean words: wordsBoolean
		pointers: pointersBoolean.
	aClass instVarNames: stringOfInstVarNames.
	classvars <- aClass classVarNames: stringOfClassVarNames.
	aClass sharedPool: stringOfPoolNames.
	superClass addSubclass: aClass.
	aClass category: categoryName.
	aClass comment: commentString.
	" Lastly add it into the system symbol table"
	aSystemDictionary at: (newName asSymbol) put: aClass.
	^ aClass
! !

! Class methodsFor: 'compiling' !

compile: aString notifying: aBlock
      Compiler compile: aString forClass: self notify: aBlock
!

compile: aString
      Compiler compile: aString forClass: self 
!

recompile: selector
      self compile: (self compiledMethodAt: selector) getSource
!

compileAll
      self selectors do: [ :sel | self recompile: sel ].
!

compileAllSubclasses
      self allSubclasses do: [ :sub | sub compileAll ].
!

compile: aString classified: aCategory
      Compiler compile: aString forClass self classified: aCategory
!

compile: aString classified: aCategory notifing: aBlock
      Compiler compile: aString forClass self classified: aCategory
		 notify: aBlock
! !

! Class methodsFor: 'Filing' !

fileOutOn: aFileStream
    " Write out class definitition. "
     aFileStream nextPutAll: superclass class name asString.
     aFileStream space.
     aFileStream nextPutAll: self kindOfSubclass.
     aFileStream space.
     name printOn: aFileStream.
     aFileStream nlTab.
     aFileStream nextPutAll: 'instanceVariableNames: '.
     self  instanceVariableString printOn: aFileStream.
     aFileStream nlTab.
     aFileStream nextPutAll: 'classVariableNames: '.
     self classVariableString printOn: aFileStream.
     aFileStream nlTab.
     aFileStream nextPutAll: 'poolDictionaries: '.
     self poolVariableString printOn: aFileStream.
     aFileStream nlTab.
     aFileStream nextPutAll: 'category: '.
     category printOn: aFileStream.
     aFileStream nextPut: $!!.
     aFileStream nl ; nl.
     " Put a comment string out if one set"
     comment notNil ifTrue: [
        aFileStream nextPutAll: name asString.
	aFileStream nextPutAll: ' comment: '.
	comment printOn: aFileStream.
	aFileStream nextPut: $!!.
	aFileStream nl ; nl.
      ].
      self class isNil ifFalse: [
	 self class fileOutMethods: aFileStream with: 'class'.
         self fileOutMethods: aFileStream with: nil.
         (self class includesSelector: #initialize ) ifTrue: [
	    aFileStream nextPutAll: name asString.
	    aFileStream nextPutAll: ' initialize !!'.
	    aFileStream nl; nl.
          ] ]
	  ifTrue: [ self fileOutMethods: aFileStream with: nil ]
!

fileOutMethods: aFileStream with: aString
     methcats isNil ifFalse: [
	methcats associationsDo: [ :assoc |
          aFileStream nextPut: $!!.
	  aFileStream space.
          aFileStream nextPutAll: name asString.
	  aFileStream space.
          aString notNil ifTrue: [ aFileStream nextPutAll: aString.
				   aFileStream space ].
          aFileStream nextPutAll: 'methodsFor: '.
	  assoc key asString printOn: aFileStream.
          aFileStream nextPut: $!!.
	  assoc value do: [ :s |
	        aFileStream nl.
		aFileStream nextChunkPut: 
			((self compiledMethodAt: s) getSource) ].
	  aFileStream space.
          aFileStream nextPut: $!!.
	  aFileStream nl; nl.
        ]
     ]
! !
