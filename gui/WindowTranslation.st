Object subclass: 'WindowTranslation'
  instanceVariableNames: 'translation scale'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! WindowTranslation class methodsFor: 'instance creation' !

translation: aOffset scale: aScale
   ^ super new translation: aOffset scale: aScale.
!

identity
   ^ super new translation: 0@0 scale: 1.0@1.0
!

window: aWindow viewport: aViewport
   | scale translation |
   scale <- aViewport width / aWindow width @
		( aViewport height / aWindow height).
   translation <- aViewport left - (scale x * aWindow left) @
		( aViewport top - (scale y * aWindow top)).
   ^ self new translation: translation scale: scale
!

fromRectangle: aRectangle
   | scale translation |
   scale <- aRectangle extent.
   translation <- aRectangle origin.
   ^ self new translation: translation scale: scale
! !

! WindowTranslation methodsFor: 'modifying' !

translation: aOffset
   translation <- aOffset
!

scale: aRectangle
   scale <- aRectangle
!

translation: aOffset scale: aScale
   translation <- aOffset.
   scale <- aScale
! !

! WindowTranslation methodsFor: 'transforming' !

scrollBy: aPoint
   ^ self translatedBy: scale * aPoint
!

translateBy: aPoint
    ^ WindowingTranslation translation: translation + aPoint scale: scale
!

scaleBy: aScale
    | newScale newTranslation |
    aScale isNil ifTrue: [ newScale <- scale. newTranslation <- translation ]
	         ifFalse: [
			   newScale <- aScale * scale.
			   newTranslation <- aScale * translation
		].
    ^ WindowingTranslation translation: newTranslation scale: newScale
!

align: point1 with: point2
    ^ self translateBy: point2 - point1
! !

! WindowTranslation methodsFor: 'translation' !

applyTo: aObject
   | newObject |
   stderr nextPutAll: 'toDisplay '.
   self printOn: stderr.
   aObject printOn: stderr. 
   newObject <- aObject scaleBy: scale.
   newObject <-  newObject translatedBy: translation
   newObject printOn: stderr. stderr nl.
   ^ newObject
!

applyInverseTo: aObject
   | newObject |
   newObject <- aObject translatedBy: ((translation x negate)@
				       (translation y negate)).
   newObject <- newObject scaleBy: (1.0 / (scale x)@
				       (1.0 / (scale y))).
   ^ newObject
!

merge: aTransform
    " Answer a new Translation that is based on our translation. "
    | newScale newTranslation |
    newScale <- scale * aTransform scale.
    newTranslation <- translation + (scale * aTransform translation).
    ^ WindowingTranslation translation: newTranslation scale: newScale
! !

! WindowTranslation methodsFor: 'accessing' !

translation
    ^ translation
!

scale
    ^ scale
!

isIdentity
    ^ 1.0 @ 1.0 = scale
!

rectangle
    ^ Rectangle origin: translation extent: scale
! !

! WindowTranslation methodsFor: 'printing' !

printOn: aStream

   aStream nextPutAll: self class name , ' translation: '.
   aStream print: translation.
   aStream nextPutAll: ' scale: '.
   aStream print: scale.
! !

