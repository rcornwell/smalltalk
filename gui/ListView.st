View subclass: 'ListView'
  instanceVariableNames: 'displayList listForm listTop currentSelection pendingSelection lineHeight'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! ListView class methodsFor: 'instance creation' !

on: aModel aspect: aName change: changeSelector
	list: aList menu: aMenu initialSelection: aItem
    | aView |
    aView <- super new.
    aView model: aModel ;
          name: aList ;
          change: changeSelector ;
     	  controller blueButtonMenu: aMenu notifying: aModel.
    ^ aView
! !

! ListView methodsFor: 'initialising' !

setContentsFrom: aCollection
    | width temp |
    currentSelection isNil
        ifFalse: [ self reverseItem: currentSelection.
	           currentSelection <- nil ].
    displayList = aCollection
        ifTrue: [ ^self ].
    displayList <- aCollection asOrderedCollection.
    listTop <- 0.
    currentSelection <- nil.
    lineHeight <- 0.
    width <- 1.
	
    displayList do: [ :string |
		temp <- string displayExtent.
		width <- width max: temp x.
		lineHeight <- lineHeight max: temp y ].
    " Make sure the form has some size "
    listForm <- Form extent: width @ (displayList size * lineHeight + 1).
    listForm white.
    1 to: displayList size do:
      [ :x | (displayList at: x)
                  displayOn: listForm
		  at: 0 @ (x - 1 * lineHeight) ]
! !

! ListView methodsFor: 'accessing' !

defaultControllerClass
    ^ListController
!

fullHeight
    listForm isNil
        ifTrue: [ ^self height ]
	ifFalse: [ ^listForm height ]
!

currentSelection
    ^currentSelection 
! !

! ListView methodsFor: 'displaying' !

displayView
    listTop isNil
        ifTrue: [ listTop <- 0 ].
    pendingSelection isNil
        ifFalse: [ self select: pendingSelection.
	           pendingSelection <- nil ].
    self showList.
!

showList
    (BitBlt destForm: Display sourceForm: listForm
            halftoneForm: Form black combinationRule: Form over
	    destOrigin: insetBox origin sourceOrigin: 0@listTop
	    extent: insetBox extent clipRect: insetBox)
	copyBits
!

emphasizeView
    currentSelection isNil
        ifTrue: [ ^nil ].
    self unGrayItem: currentSelection.
    self reverseItem: currentSelection.
    self showList
!

deEmphasizeView
    currentSelection isNil
        ifTrue: [ ^nil ].
    self reverseItem: currentSelection.
    self grayItem: currentSelection.
    self showList
! !

! ListView methodsFor: 'scrolling' !

scrollTo: anInteger
    listTop <- anInteger.
    listTop > (listForm height - extent y)
        ifTrue: [ listTop <- listForm height - extent y ].
    listTop < 0
        ifTrue: [ listTop <- 0 ].
    self showList
!

scrollPosition
    listTop isNil
        ifTrue: [ ^0 ]
	ifFalse: [ ^listTop ]
! !

! ListView methodsFor: 'selecting' !

select
    | aPoint selection |
    aPoint <- Sensor mousePoint.
    (insetBox containsPoint: aPoint)
        ifFalse: [ ^nil ].
    selection <- aPoint y - offset y + listTop.
    selection <- selection // lineHeight + 1.
    (selection < (displayList size + 1) and: [ selection > 0 ])
        ifFalse: [ ^nil ].
    currentSelection isNil            "deselect current selection"
	ifFalse: [ self reverseItem: currentSelection ].
    currentSelection == selection      "deselecting?"
        ifTrue: [ currentSelection <- nil ]
	ifFalse: [ currentSelection <- selection.
                   self reverseItem: currentSelection ].
    self showList.
    self changed
!

setSelection: anInteger
    anInteger isNil
        ifTrue: [ ^nil ].
    pendingSelection <- anInteger
!

select: anInteger
    anInteger isNil
        ifTrue: [ ^nil ].
    (anInteger < (displayList size + 1) and: [ anInteger > 0 ])
        ifFalse: [ ^nil ].
    currentSelection isNil
        ifFalse: [ self reverseItem: currentSelection ].
    currentSelection == anInteger
        ifTrue: [ currentSelection <- nil ]
	ifFalse: [ currentSelection <- anInteger.
	           self reverseItem: currentSelection ].
    self changed
!

reverseItem: selection
    listForm reverse: (0 @ (selection - 1 * lineHeight)
                         extent: (listForm width @ lineHeight)).
!

grayItem: selection
    listForm fill: (0 @ (selection - 1 * lineHeight)
                      extent: (listForm width @ lineHeight))
	     rule: Form under
	     mask: Form veryLightGray
!

unGrayItem: selection
    listForm white: (0 @ (selection - 1 * lineHeight)
                      extent: (listForm width @ lineHeight)).
    (displayList at: selection) displayOn: listForm
                                at: 0 @ (selection - 1 * lineHeight)
! !

! ListView methodsFor: 'updating' !

update: aSymbol
    name == aSymbol
        ifTrue: [ self setContentsFrom: (model preform: aSymbol).
                  self isLocked ifTrue: [ self display ] ]
! 

changed
    | selection |
    (model notNil and: [ name notNil and: [ change notNil ] ])
        ifTrue:
	   [ currentSelection isNil
	         ifTrue: [ selection <- nil ]
		 ifFalse: [ selection <- displayList at: currentSelection ].
	     model preform: change with: selection ]
! !

