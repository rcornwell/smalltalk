ScrollController subclass: 'ListController'
  instanceVariableNames: ''
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! ListController methodsFor: 'control' !

redButtonActivity
    view select.
    Sensor waitNoButton
! !

View subclass: 'ListView'
  instanceVariableNames: 'displayList listForm listTop currentSelection pendingSelection lineHeight printFlag oneItem'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! ListView class methodsFor: 'instance creation' !

new: aRectangle on: anArray
    | aView |
    aView <- super new: aRectangle.
    aView oneItem: false ;
	  printItems: false.
    aView setContentsFrom: anArray.
    ^aView
!

on: aModel printItems: aBoolean oneItem: aFlag aspect: aName 
	change: changeSelector menu: aMenu
	 initialSelection: aItem
    | aView |
    aView <- super new.
    aView model: aModel ;
	  oneItem: aFlag ;
	  printItems: aBoolean ;
          change: changeSelector ;
          name: aName ;
	  setSelection: aItem ;
     	  controller blueButtonMenu: aMenu notifying: aModel.
    ^ aView
!

on: aModel aspect: aName change: changeSelector
	menu: aMenu initialSelection: aItem
    | aView |
    aView <- super new.
    aView model: aModel ;
	  oneItem: false ;
	  printItems: false ;
          change: changeSelector ;
          name: aName ;
	  setSelection: aItem ;
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

    (oneItem and: [ displayList size = 1 ]) ifTrue: [ pendingSelection <- 1 ].
	
    displayList do: [ :string |
		printFlag ifTrue: [ string <- string printString ].
		temp <- string displayExtent.
		width <- width max: temp x.
		lineHeight <- lineHeight max: temp y ].
    " Make sure the form has some size "
    listForm <- Form extent: width @ (displayList size * lineHeight + 1).
    listForm white.
    1 to: displayList size do:
      [ :x | temp <- displayList at: x.
	     printFlag ifTrue: [ temp <- temp printString ].
             temp displayOn: listForm
		  at: 0 @ (x - 1 * lineHeight) ]
! !

! ListView methodsFor: 'accessing' !

defaultControllerClass
    ^ListController
!

fullHeight
    listForm isNil
        ifTrue: [ ^self height ]
	ifFalse: [ ^listForm height + 10 ]
!

currentSelection
    ^currentSelection 
! !

! ListView methodsFor: 'modifing' !

oneItem: aBoolean
    oneItem <- aBoolean
!

printItems: aBoolean
    printFlag <- aBoolean
! !

! ListView methodsFor: 'displaying' !

display
    displayed <- true.
    extent isNil
        ifTrue: [ self error: 'ListView has no extent!!' ].
    Display white: (offset extent: extent).
    Display border: (offset extent: extent)
            widthRectangle: borderWidth
	    mask: Form black.
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

emphasize
    currentSelection isNil
        ifTrue: [ ^nil ].
    self unGrayItem: currentSelection.
    self reverseItem: currentSelection.
    self showList
!

deEmphasize
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
    | temp off |
    off <- 0 @ (selction - 1 * lineHeight).
    listForm white: (off extent: (listForm width @ lineHeight)).
    temp <- displayList at: selection.
    printFlag ifTrue: [ temp <- temp printString ].
    temp displayOn: listForm at: off
! !

! ListView methodsFor: 'controlling' !

selectItem: anInteger
    anInteger isNil
        ifTrue: [ ^nil ].
    pendingSelection <- anInteger
!

setSelection: aItem
    | temp | 
    1 to: displayList size do:
      [ :x | temp <- displayList at: x.
	     printFlag ifTrue: [ temp <- temp printString ].
	     temp = aItem ifTrue: [ pendingSelection <- x ].
      ].
! !

! ListView methodsFor: 'updating' !

changed
    | selection |
    (model notNil and: [ name notNil and: [ change notNil ] ])
        ifTrue:
	   [ currentSelection isNil
	         ifTrue: [ selection <- nil ]
		 ifFalse: [ selection <- displayList at: currentSelection ].
	     model preform: change with: selection ]
! !

