
! Rectangle methodsFor: 'instance creation' !

originFromUser
    | bitblt position deltaX deltaY nib |
    nib <- Form new extent: 1@1.
    nib black.
    bitblt <- BitBlt destForm: Display sourceForm: nib
                     halftoneForm: nil
                     combinationRule: Form reverse
                     destOrigin: 0@0 sourceOrigin: 0@0
                     extent: (1@1) clipRect: nil.
    bitblt drawFrom: origin
           to: corner x @ origin y.
    bitblt drawFrom: origin x @ (origin y + 1)
           to: origin x @ corner y.
    bitblt drawFrom: corner x @ (origin y + 1)
           to: corner.
    bitblt drawFrom: (origin x + 1) @ corner y
           to: (corner x - 1) @ corner y.
    Cursor origin showWhile: [
        [ Sensor waitMouse. Sensor anyButtonPressed ]
            whileTrue:
                [ position <- Sensor mousePoint.
	          position == origin
	              ifFalse: [ bitblt drawFrom: origin
                                        to: corner x @ origin y.
                                 bitblt drawFrom: origin x @ (origin y + 1)
                                        to: origin x @ corner y.
                                 bitblt drawFrom: corner x @ (origin y + 1)
                                        to: corner.
                                 bitblt drawFrom: (origin x + 1) @ corner y
                                        to: (corner x - 1) @ corner y.
                                 origin <- position.
                                 bitblt drawFrom: origin
                                        to: corner x @ origin y.
                                 bitblt drawFrom: origin x @ (origin y + 1)
                                        to: origin x @ corner y.
                                 bitblt drawFrom: corner x @ (origin y + 1)
                                        to: corner.
                                 bitblt drawFrom: (origin x + 1) @ corner y
                                        to: (corner x - 1) @ corner y ] ] ].
    bitblt drawFrom: origin
           to: corner x @ origin y.
    bitblt drawFrom: origin x @ (origin y + 1)
           to: origin x @ corner y.
    bitblt drawFrom: corner x @ (origin y + 1)
           to: corner.
    bitblt drawFrom: (origin x + 1) @ corner y
           to: (corner x - 1) @ corner y.
    origin <= corner
        ifTrue: [ position <- origin.
		  origin <- corner.
		  corner <- position ]
!

cornerFromUser
    | bitblt position deltaX deltaY nib |
    nib <- Form new extent: 1@1.
    nib black.
    bitblt <- BitBlt destForm: Display sourceForm: nib
                     halftoneForm: nil
                     combinationRule: Form reverse
                     destOrigin: 0@0 sourceOrigin: 0@0
                     extent: (1@1) clipRect: nil.
    bitblt drawFrom: origin
           to: corner x @ origin y.
    bitblt drawFrom: origin x @ (origin y + 1)
           to: origin x @ corner y.
    bitblt drawFrom: corner x @ (origin y + 1)
           to: corner.
    bitblt drawFrom: (origin x + 1) @ corner y
           to: (corner x - 1) @ corner y.
    Cursor corner showWhile: [
        [ Sensor waitMouse. Sensor anyButtonPressed ]
            whileTrue:
                [ position <- Sensor mousePoint.
	          position == corner
	              ifFalse: [ 
				 bitblt drawFrom: origin
                                        to: corner x @ origin y.
                                 bitblt drawFrom: origin x @ (origin y + 1)
                                        to: origin x @ corner y.
                                 bitblt drawFrom: corner x @ (origin y + 1)
                                        to: corner.
                                 bitblt drawFrom: (origin x + 1) @ corner y
                                        to: (corner x - 1) @ corner y.
                                 corner <- position.
                                 bitblt drawFrom: origin
                                        to: corner x @ origin y.
                                 bitblt drawFrom: origin x @ (origin y + 1)
                                        to: origin x @ corner y.
                                 bitblt drawFrom: corner x @ (origin y + 1)
                                        to: corner.
                                 bitblt drawFrom: (origin x + 1) @ corner y
                                        to: (corner x - 1) @ corner y ] ] ].
    bitblt drawFrom: origin
           to: corner x @ origin y.
    bitblt drawFrom: origin x @ (origin y + 1)
           to: origin x @ corner y.
    bitblt drawFrom: corner x @ (origin y + 1)
           to: corner.
    bitblt drawFrom: (origin x + 1) @ corner y
           to: (corner x - 1) @ corner y.
    origin <= corner
        ifTrue: [ position <- origin.
		  origin <- corner.
		  corner <- position ]
! 

cornerFromUserMin: aSize
    | bitblt position deltaX deltaY nib min |
    min <- origin + aSize.
    nib <- Form new extent: 1@1.
    nib black.
    bitblt <- BitBlt destForm: Display sourceForm: nib
                     halftoneForm: nil
                     combinationRule: Form reverse
                     destOrigin: 0@0 sourceOrigin: 0@0
                     extent: (1@1) clipRect: nil.
    bitblt drawFrom: origin
           to: corner x @ origin y.
    bitblt drawFrom: origin x @ (origin y + 1)
           to: origin x @ corner y.
    bitblt drawFrom: corner x @ (origin y + 1)
           to: corner.
    bitblt drawFrom: (origin x + 1) @ corner y
           to: (corner x - 1) @ corner y.
    Cursor corner showWhile: [
        [ Sensor waitMouse. Sensor anyButtonPressed ]
            whileTrue:
                [ position <- Sensor mousePoint.
	          position == corner
	              ifFalse: [ 
				 bitblt drawFrom: origin
                                        to: corner x @ origin y.
                                 bitblt drawFrom: origin x @ (origin y + 1)
                                        to: origin x @ corner y.
                                 bitblt drawFrom: corner x @ (origin y + 1)
                                        to: corner.
                                 bitblt drawFrom: (origin x + 1) @ corner y
                                        to: (corner x - 1) @ corner y.
                                 corner <- position min: min.
                                 bitblt drawFrom: origin
                                        to: corner x @ origin y.
                                 bitblt drawFrom: origin x @ (origin y + 1)
                                        to: origin x @ corner y.
                                 bitblt drawFrom: corner x @ (origin y + 1)
                                        to: corner.
                                 bitblt drawFrom: (origin x + 1) @ corner y
                                        to: (corner x - 1) @ corner y ] ] ].
    bitblt drawFrom: origin
           to: corner x @ origin y.
    bitblt drawFrom: origin x @ (origin y + 1)
           to: origin x @ corner y.
    bitblt drawFrom: corner x @ (origin y + 1)
           to: corner.
    bitblt drawFrom: (origin x + 1) @ corner y
           to: (corner x - 1) @ corner y.
    origin <= corner
        ifTrue: [ position <- origin.
		  origin <- corner.
		  corner <- position ]
! !

! Rectangle class methodsFor: 'instance creation' !

fromUserMin: aSize
    | origin corner bitblt position min deltaX deltaY nib |
    Cursor origin showWhile: [ Sensor waitButton ].
    origin <- Sensor mousePoint.
    corner <- aSize + Sensor mousePoint.
    min <- corner.
    nib <- Form new extent: 1@1.
    nib black.
    bitblt <- BitBlt destForm: Display sourceForm: nib
                     halftoneForm: nil
                     combinationRule: Form reverse
                     destOrigin: 0@0 sourceOrigin: 0@0
                     extent: (1@1) clipRect: nil.
    bitblt drawFrom: origin
           to: corner x @ origin y.
    bitblt drawFrom: origin x @ (origin y + 1)
           to: origin x @ corner y.
    bitblt drawFrom: corner x @ (origin y + 1)
           to: corner.
    bitblt drawFrom: (origin x + 1) @ corner y
           to: (corner x - 1) @ corner y.
    Cursor corner showWhile: [
        [ Sensor waitMouse. Sensor anyButtonPressed ]
            whileTrue:
                [ position <- Sensor mousePoint.
	          position == corner
	              ifFalse: [ 
				 bitblt drawFrom: origin
                                        to: corner x @ origin y.
                                 bitblt drawFrom: origin x @ (origin y + 1)
                                        to: origin x @ corner y.
                                 bitblt drawFrom: corner x @ (origin y + 1)
                                        to: corner.
                                 bitblt drawFrom: (origin x + 1) @ corner y
                                        to: (corner x - 1) @ corner y.
                                 corner <- position min: min.
                                 bitblt drawFrom: origin
                                        to: corner x @ origin y.
                                 bitblt drawFrom: origin x @ (origin y + 1)
                                        to: origin x @ corner y.
                                 bitblt drawFrom: corner x @ (origin y + 1)
                                        to: corner.
                                 bitblt drawFrom: (origin x + 1) @ corner y
                                        to: (corner x - 1) @ corner y ] ] ].
    bitblt drawFrom: origin
           to: corner x @ origin y.
    bitblt drawFrom: origin x @ (origin y + 1)
           to: origin x @ corner y.
    bitblt drawFrom: corner x @ (origin y + 1)
           to: corner.
    bitblt drawFrom: (origin x + 1) @ corner y
           to: (corner x - 1) @ corner y.
    origin <= corner
        ifTrue: [ ^self origin: origin corner: corner ]
	ifFalse: [ ^self origin: corner corner: origin ]
! !

