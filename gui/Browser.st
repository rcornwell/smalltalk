
Object subclass: 'Browser'
  instanceVariableNames: 'catList classList methCatsList theCat theClass theMethodCat theMethod methodType methodShow'
  classVariableNames: 'CatMenu1 CatMenu2 ClassMenu ClassCatMenu1 ClassCatMenu2 MethMenu'
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! Browser methodsFor: 'initialising' !

newBrowser
    | topView classView instanceView |
    catList <- Browser allCategories.
    classList <- OrderedCollection new.
    methCatsList <- OrderedCollection new.
    theCat <- nil.
    theClass <- nil.
    theMethodCat <- nil.
    methodShow <- #emptyClass.
    theMethod <- nil.
    methodType <- #instance.
    topView <- StandardSystemView new
                   label: 'Class Hierarchy Browser'; yourself.
    topView addSubView:
	   (ListView on: self 
		   aspect: #catList
		   change: #categorySelection:
		   menu: #catMenu
		   initialSelection: nil)
	   in: (0@0 extent: 0.25@0.5).
    topView addSubView:
	   (ListView on: self 
		   printItems: true
		   oneItem: false
		   aspect: #classList
		   change: #classSelection:
		   menu: #classMenu
		   initialSelection: nil)
	   in: (0.25@0 extent: 0.25@0.4).

    instanceView <- SwitchView new.
    instanceView model: self.
    instanceView label: 'Instance' .  
    instanceView selector: #isInstanceShown .
    instanceView controller selector: #showInstance .
    instanceView name: #instanceSwitch .
     topView addSubView: instanceView in: (0.25@0.4 extent: 0.125@0.1).

    classView <- SwitchView new.
    classView model: self.
    classView label:  'Class'.  
    classView selector: #isClassShown .
    classView controller selector: #showClass . 
    classView name: #classSwitch .
     topView addSubView: classView in: (0.375@0.4 extent: 0.125@0.1).

    topView addSubView:
	   (ListView on: self 
		   printItems: true
		   oneItem: false
		   aspect: #classCatList
		   change: #classCatSelection:
		   menu: #classCatMenu
		   initialSelection: nil)
	   in: (0.5@0 extent: 0.25@0.5).
    topView addSubView:
	   (ListView on: self 
		   printItems: true
		   oneItem: false
		   aspect: #methodList
		   change: #methodListSelection:
		   menu: #methodListMenu
		   initialSelection: nil)
	   in: (0.75@0 extent: 0.25@0.5).
    topView addSubView:
         (TextView on: self
		   aspect: #methodText
		   change: #methodText: 
		   menu: nil
		   initialSelection: nil)
	    in: (0@ 0.5 extent: 1.0@0.5).
    topView open.
!

newOnCategory: aString
    | topView classView instanceView |
    catList <- OrderedCollection new.
    catList add: aString.
    classList <- OrderedCollection new.
    methCatsList <- OrderedCollection new.
    theCat <- nil.
    theClass <- nil.
    theMethodCat <- nil.
    methodShow <- #emptyClass.
    theMethod <- nil.
    methodType <- #instance.
    topView <- StandardSystemView new
                   label: 'Category Browser'; yourself.
    topView addSubView:
	   (ListView on: self 
		   printItems: false
		   oneItem: true
		   aspect: #catList
		   change: #categorySelection:
		   menu: #catMenu
		   initialSelection: nil)
	   in: (0@0 extent: 0.33@0.1).
    topView addSubView:
	   (ListView on: self 
		   printItems: true
		   oneItem: false
		   aspect: #classList
		   change: #classSelection:
		   menu: #classMenu
		   initialSelection: nil)
	   in: (0@0.1 extent: 0.33@0.4).

    instanceView <- SwitchView new.
    instanceView model: self.
    instanceView label: 'Instance' .  
    instanceView selector: #isInstanceShown .
    instanceView controller selector: #showInstance .
    instanceView name: #instanceSwitch .
     topView addSubView: instanceView in: (0@0.4 extent: 0.125@0.1).

    classView <- SwitchView new.
    classView model: self.
    classView label:  'Class'.  
    classView selector: #isClassShown .
    classView controller selector: #showClass . 
    classView name: #classSwitch .
     topView addSubView: classView in: (0.125@0.4 extent: 0.125@0.1).

    topView addSubView:
	   (ListView on: self 
		   printItems: true
		   oneItem: false
		   aspect: #classCatList
		   change: #classCatSelection:
		   menu: #classCatMenu
		   initialSelection: nil)
	   in: (0.33@0 extent: 0.33@0.5).
    topView addSubView:
	   (ListView on: self 
		   printItems: true
		   oneItem: false
		   aspect: #methodList
		   change: #methodListSelection:
		   menu: #methodListMenu
		   initialSelection: nil)
	   in: (0.66@0 extent: 0.33@0.5).
    topView addSubView:
         (TextView on: self
		   aspect: #methodText
		   change: #methodText: 
		   menu: nil
		   initialSelection: nil)
	    in: (0@ 0.5 extent: 1.0@0.5).
    topView open.
!
newOnClass: aClass
    | topView classView instanceView |
    catList <- OrderedCollection new.
    classList <- OrderedCollection new.
    classList add: (aClass name asString).
    methCatsList <- OrderedCollection new.
    theCat <- nil.
    theClass <- nil.
    theMethodCat <- nil.
    methodShow <- #emptyClass.
    theMethod <- nil.
    methodType <- #instance.
    topView <- StandardSystemView new
                   label: 'Class Browser'; yourself.
    topView addSubView:
	   (ListView on: self 
		   printItems: true
		   oneItem: true
		   aspect: #classList
		   change: #classSelection:
		   menu: #classMenu
		   initialSelection: nil)
	   in: (0.0@0 extent: 0.5@0.1).

    instanceView <- SwitchView new.
    instanceView model: self.
    instanceView label: 'Instance' .  
    instanceView selector: #isInstanceShown .
    instanceView controller selector: #showInstance .
    instanceView name: #instanceSwitch .
     topView addSubView: instanceView in: (0.5@0.0 extent: 0.125@0.1).

    classView <- SwitchView new.
    classView model: self.
    classView label:  'Class'.  
    classView selector: #isClassShown .
    classView controller selector: #showClass . 
    classView name: #classSwitch .
     topView addSubView: classView in: (0.775@0.0 extent: 0.125@0.1).

    topView addSubView:
	   (ListView on: self 
		   printItems: true
		   oneItem: false
		   aspect: #classCatList
		   change: #classCatSelection:
		   menu: #classCatMenu
		   initialSelection: nil)
	   in: (0@0.1 extent: 0.5@0.5).
    topView addSubView:
	   (ListView on: self 
		   printItems: true
		   oneItem: false
		   aspect: #methodList
		   change: #methodListSelection:
		   menu: #methodListMenu
		   initialSelection: nil)
	   in: (0.5@0.1 extent: 0.5@0.5).
    topView addSubView:
         (TextView on: self
		   aspect: #methodText
		   change: #methodText: 
		   menu: nil
		   initialSelection: nil)
	    in: (0@ 0.5 extent: 1.0@0.5).
    topView open.
!

newOnClass: aClass protocol: aString
    | topView classView instanceView |
    catList <- OrderedCollection new.
    classList <- OrderedCollection new.
    classList add: aClass name asString.
    methCatsList <- OrderedCollection new.
    methCatsList add: aString.
    theCat <- nil.
    theClass <- nil.
    theMethodCat <- nil.
    methodShow <- #emptyClass.
    theMethod <- nil.
    methodType <- #instance.
    topView <- StandardSystemView new
                   label: ('Protocol Browser for ', aClass name asString)
			; yourself.
    topView addSubView:
	   (ListView on: self 
		   printItems: true
		   oneItem: true
		   aspect: #classCatList
		   change: #classCatSelection:
		   menu: #classCatMenu
		   initialSelection: nil)
	   in: (0@0.1 extent: 0.5@0.5).
    topView addSubView:
	   (ListView on: self 
		   printItems: true
		   oneItem: false
		   aspect: #methodList
		   change: #methodListSelection:
		   menu: #methodListMenu
		   initialSelection: nil)
	   in: (0.5@0.1 extent: 0.5@0.5).
    topView addSubView:
         (TextView on: self
		   aspect: #methodText
		   change: #methodText: 
		   menu: nil
		   initialSelection: nil)
	    in: (0@ 0.5 extent: 1.0@0.5).
    topView open.
!

newOnClass: aClass protocol: aString
    | topView classView instanceView |
    catList <- OrderedCollection new.
    classList <- OrderedCollection new.
    classList add: aClass name asString.
    methCatsList <- OrderedCollection new.
    methCatsList add: aString.
    theCat <- nil.
    theClass <- nil.
    theMethodCat <- nil.
    methodShow <- #emptyClass.
    theMethod <- nil.
    methodType <- #instance.
    topView <- StandardSystemView new
                   label: ('Protocol Browser for ', aClass name asString)
			; yourself.
    topView addSubView:
	   (ListView on: self 
		   printItems: true
		   oneItem: true
		   aspect: #classCatList
		   change: #classCatSelection:
		   menu: #classCatMenu
		   initialSelection: nil)
	   in: (0@0.1 extent: 0.5@0.5).
    topView addSubView:
	   (ListView on: self 
		   printItems: true
		   oneItem: false
		   aspect: #methodList
		   change: #methodListSelection:
		   menu: #methodListMenu
		   initialSelection: nil)
	   in: (0.5@0.1 extent: 0.5@0.5).
    topView addSubView:
         (TextView on: self
		   aspect: #methodText
		   change: #methodText: 
		   menu: nil
		   initialSelection: nil)
	    in: (0@ 0.5 extent: 1.0@0.5).
    topView open.
! !

! Browser methodsFor: 'accessing' !

isInstanceShown
    ^  methodType == #instance
!

isClassShown
    ^ methodType == #class
!
   
showInstance
    theMethod <- nil.
    theMethodCat <- nil.
    methodType <- #instance.
    self changed: #classSwitch;
	 changed: #classCatList;
         changed: #methodList;
	 changed: #methodText
!

showClass
    theMethod <- nil.
    theMethodCat <- nil.
    methodType <- #class.
    self changed: #instanceSwitch;
	 changed: #classCatList;
         changed: #methodList;
	 changed: #methodText
!

category
!

categorySelection: aString
    | aStream classString |
    theCat <- aString.
    classList <- OrderedCollection new: 0.
    methodShow <- #emptyClass.
    theCat isNil
        ifFalse: [  methodShow <- #emptyClassCat.
		    (Object allClassesForCategory: aString)
			do: [ :class | classList add: class name asString ]].
    theClass <- nil.
    theMethodCat <- nil.
    theMethod <- nil.
    self changed: #classList;
	 changed: #classCatList;
         changed: #methodList;
         changed: #methodText
!

catList
	^ catList
!

catMenu
    theCat isNil ifTrue: [
	CatMenu1 isNil ifTrue: [
 	    CatMenu1 <- Menu labelArray: #( 'add category' 'update')
			     lines: #(1)
			     selectors: #(addCategory update)
	 ].
	 ^ CatMenu1
    ] ifFalse: [
	CatMenu2 isNil ifTrue: [
 	    CatMenu2 <- Menu labelArray: #( 'file out' 'spawn' 
					     'add category' 'rename' 'remove'
					     'update')
			     lines: #(2 5)
			     selectors: #(fileOutCat spawnCat
					 addCategory renameCategory 
						removeCategory
						update).
	].
	^ CatMenu2
    ]
!

classList
    ^classList
!

classSelection: aString
    | aStream classString |
    aString isNil
        ifTrue: [ theClass <- nil ]
        ifFalse: [ theClass <- Smalltalk at: aString asSymbol
                                                     ifAbsent: [ nil ]
	].
    theMethodCat <- nil.
    theMethod <- nil.
    methodShow <- #classDef.
    self changed: #classCatList ;
         changed: #methodList;
         changed: #methodText
!

classCatSelection: aString
    theMethodCat <- aString.
    methodShow <- #emptyMethod.
    self changed: #methodList
!

classCatList
    | class |
    theClass isNil ifTrue: [ ^ OrderedCollection new: 0 ].
    class <- theClass.
    self isClassShown ifTrue: [ class <- class class ].
    ^ class methodCats
!

classMenu
    theClass isNil ifFalse: [
	ClassMenu isNil ifTrue: [
 	    ClassMenu <- Menu labelArray: 
			      #( 'file out' 'spawn' 'spawn hierarchy'
				 'heirarchy' 'definition' 'comment' 'protocols'
				 'inst var refs' 'class var refs' 'class refs'
				 'rename' 'remove')
			     lines: #(3 7 10 )
			     selectors: #(fileOutClass spawnClass spawnHeir
				  heirarchy classDef classComment classProto
				  instVarRefs classVarRefs classRefs 
				  renameClass removeClass).
	].
	^ ClassMenu
    ]
    ^ nil
!
	

classCatMenu
    theMethodCat isNil ifTrue: [
	ClassCatMenu1 isNil ifTrue: [
 	    ClassCatMenu1 <- Menu labelArray: #( 'add protocol')
			     lines: #()
			     selectors: #(addProtocol)
	 ].
	 ^ ClassCatMenu1
    ] ifFalse: [
	ClassCatMenu2 isNil ifTrue: [
 	    ClassCatMenu2 <- Menu labelArray: #( 'file out' 'spawn' 
					     'add protocol' 'rename' 'remove')
			     lines: #(2)
			     selectors: #(fileOutCat spawnMethCat
					 addProtocol renameProtocol 
						removeProtocol).
	].
	^ ClassCatMenu2
    ]
!

methodList
    | class |
    (theMethodCat isNil or: [ theClass isNil ]) ifTrue:
		 [ ^ OrderedCollection new: 0 ].
    class <- theClass.
    self isClassShown ifTrue: [ class <- class class ].
    ^ class methodsForCat: theMethodCat
!

methodListSelection: aString
    theMethod <- aString.
    methodShow <- #method.
    self changed: #methodText
!

methodListMenu
    theMethod isNil ifFalse: [
	MethMenu isNil ifTrue: [
 	    MethMenu <- Menu labelArray: #( 'file out' 'spawn' 
					     'senders' 'implementors' 'messages'
					     'move' 'remove')
			     lines: #(2 5)
			     selectors: #(fileOutMeth spawnMeth
					 senders impementors messages
					 renameMethod removeMethod).
	].
	^ MethMenu
    ]
    ^ nil
!

methodText
    | class |
    methodShow == #emptyClass ifTrue: [
	^ 'NameOfSuperClass subclass: ''NameOfClass''
    instanceVariableNames: ''instVarName1 instVarName2''
    classVariableNames: ''classVarName1 classVarName2''
    poolDictionaries: ''''
    category: ''classCategory''
'
    ].
    methodShow == #emptyClassCat ifTrue: [
	^ 'NameOfSuperClass subclass: ''NameOfClass''
    instanceVariableNames: ''instVarName1 instVarName2''
    classVariableNames: ''classVarName1 classVarName2''
    poolDictionaries: ''''
    category: ' , (theCat printString).
    ].
    methodShow == #emptyMethod ifTrue: [
	^ 'message selector and argument names
"comment stating purpose of method"

| temporary variable names |
statements
'
    ].
    methodShow == #method ifTrue: [
	    class <- theClass.
	    self isClassShown ifTrue: [ class <- class class ].
	    ^ (class compiledMethodAt: theMethod asSymbol) getSource
    ].
    ^ 'Unsupported methodShow of ', (methodShow printString).
!

methodMenu
    ^ nil
!

accept: aString from: aController
    (theClass isNil or: [ theMethod isNil ])
        ifTrue: [ ^nil ].
    theClass compile: aString notifying: self
! !

! Browser methodsFor: 'menus' !
! 
fileOutCat
!

spawnCat
!

addCategory
!

renameCategory
! 

removeCategory
!

update
!

fileOutClass
!

spawnClass
!

spawnHeir
!

heirarchy
!

classDef
!

classComment
!

classProto
!

instVarRefs
!

classVarRefs
!

classRefs
!

renameClass
!

removeClass
!

fileOutCat
!

spawnMethCat
!

addProtocol
!

renameProtocol
!

removeProtocol
!

fileOutMeth
!

spawnMeth
!

senders
!

impementors
!

messages
!

renameMethod
!

removeMethod
! !

! Class methodsFor: 'Method Categories' !

methodCats
	| coll |
	coll <- OrderedCollection new: 0.
	methcats isNil ifTrue: [ ^ coll ].
	methcats keysDo: [ :key | coll add: key ].
	^ coll

!

methodsForCat: aString
	| coll set |
	coll <- OrderedCollection new: 0.
	methcats isNil ifTrue: [ ^ coll ].
	set <- methcats at: aString asSymbol ifAbsent: [ ^ coll ].
	set do: [ :meth | coll add: meth ].
	^ coll
! !

