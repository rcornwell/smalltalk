"Added some methods to class String to display a string on a Form" !

! String methodsFor: 'displaying' !

display
    ^Display displayString: self at: 0@0
                 clippingBox: Display boundingBox
		 rule: Form over
		 mask: Form black
!

displayAt: aPoint
    ^Display displayString: self at: aPoint
                 clippingBox: Display boundingBox
		 rule: Form over
		 mask: Form black
!

displayOn: aForm
    ^aForm displayString: self at: 0@0
                 clippingBox: aForm boundingBox
		 rule: Form over
		 mask: Form black
!

displayOn: aForm at: aPoint
    ^aForm displayString: self at: aPoint
                 clippingBox: aForm boundingBox
		 rule: Form over
		 mask: Form black
!

displayOn: aForm at: aPoint
                 clippingBox: clipRectangle
    ^aForm displayString: self at: aPoint
                 clippingBox: clipRectangle
		 rule: Form over
		 mask: Form black
!

displayOn: aForm at: aPoint
                 clippingBox: clipRectangle
		 rule: rule
    ^aForm displayString: self at: aPoint
                 clippingBox: clipRectangle
		 rule: rule
		 mask: Form black
!

displayOn: aForm at: aPoint
                 clippingBox: clipRectangle
		 rule: rule
		 mask: aMask
    ^aForm displayString: self at: aPoint
                 clippingBox: clipRectangle
		 rule: rule
		 mask: aMask
! !

! Form methodsFor: 'displaying text' !

displayString: aString at: aPoint
                 clippingBox: clipRectangle
                 rule: rule
                 mask: mask
    | scanner code done |
    scanner <- CharacterScanner text: aString 
	destForm: self font: Font systemFont
        combinationRule: rule destOrigin: aPoint
        extent: ((self width)@(self height)) clipRect: clipRectangle.
    done <- false.
    [ done ] whileFalse: [
        code <- scanner scanword: aString size.
    	done <- scanner preform: code
    ].
! !

! Form methodsFor: 'initialize-release' !

fromString: aString 
    | extent |
    extent <- aString displayExtent.
    self extent: extent.
    self displayString: aString at: 0@0
                 clippingBox: (Rectangle origin: 0@0 corner: extent)
                 rule: Form over
                 mask: Form black
! !
 
! String methodsFor: 'display sizing' !

boundingBox
    | scanner code width done |
    width <- 0.
    scanner <- CharacterScanner text: self 
	destForm: Display font: Font systemFont.
    scanner printing: false.
    done <- false.
    [ done ] whileFalse: [
        code <- scanner scanword: aString size.
	width <- width max: scanner destX.
    	done <- scanner preform: code
    ].
    width <- width max: scanner destX.
    scanner nextline.
    ^ Rectangle origin: 0@0 extent: (width @ scanner destY)
! !

