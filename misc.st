" Methods for Class misc extra classes"

" $Id: $ "

"
 $Log: $
"

Stream subclass: 'Random'
       instanceVariableNames: 'seed'
       classVariableNames: ''
       poolDictionaries: ''
       category: nil
!

Random comment: 
'My instances are generator streams that produce random numbers, which are 
floating point values between 0 and 1.'!

!Random class methodsFor: 'instance creation'!

new
    ^self basicNew setSeed
! !

!Random methodsFor: 'testing'!

chiSquare
    "returns on Sun3 93.40000000000009"
    ^self chiSquare: 1000 range: 100
!

chiSquare: n range: r
    | f t seed |
    seed <- 1234567.
    f <- Array new: r + 1.
    1 to: r + 1 do: [ :i | f at: i put: 0 ].
    n timesRepeat:
        [ seed <- (seed * 31415821) + 1 bitAnd: 16r3FFFFFFF.
          t <- seed \\ r.
          f at: t + 1 put: (f at: t + 1) + 1 ].
    t <- 0.
    1 to: r do: [ :i | t <- t + (f at: i) squared ].
    ^r asFloat * t / n - n

! !


!Random methodsFor: 'basic'!

atEnd
    ^false
!

next
    | value |
    "From Sedgewick's 'Algorithms', based on Lehmer's method"
    seed <- (seed * 31415821) + 1 bitAnd: 16r3FFFFFFF.
    ^seed / 16r3FFFFFFF.0
!

nextPut: value
    self shouldNotImplement
!

next: anInteger
    | collection |
    collection <- OrderedCollection new.
    anInteger timesRepeat: [ collection add: self next ]. 
    ^collection
!

nextMatchFor: aNumber
    ^self next = aNumber
! !

!Random methodsFor: 'private'!

setSeed
    seed <- Time secondClock
! !
Magnitude subclass: 'Date'
          instanceVariableNames: 'days'
          classVariableNames: ''
          poolDictionaries: ''
          category: nil
!

Date comment: 
'My instances represent dates.  My base date is defined to be Jan 1, 1901.
I provide methods for instance creation (including via "symbolic" dates, 
such as "Date newDay: 14 month: #Feb year: 1990"' !

Smalltalk at: #DayNameDict put: Dictionary new!
Smalltalk at: #MonthNameDict put: Dictionary new!

| dayNames |
    dayNames <- #(
                 (monday mon)   "1"
                 (tuesday tue)  "2"
                 (wednesday wed) "3"
                 (thursday thu) "4"
                 (friday fri)   "5"
                 (saturday sat) "6"
                 (sunday sun)   "7"
                ).
    1 to: dayNames size do:
        [ :dayIndex | (dayNames at: dayIndex) do:
            [ :name | DayNameDict at: name put: dayIndex ] ].
!

| monthNames |
    monthNames <- #(
                 (january   jan)        "1"
                 (february  feb)        "2"
                 (march     mar)        "3"
                 (april     apr)        "4"
                 (may)                  "5"
                 (june      jun)        "6"
                 (july      jul)        "7"
                 (august    aug)        "8"
                 (september sep)        "9"
                 (october   oct)        "10"
                 (november  nov)        "11"
                 (december  dec)        "12"
                ).
    1 to: monthNames size do:
        [ :monthIndex | (monthNames at: monthIndex) do:
            [ :name | MonthNameDict at: name put: monthIndex ] ].
!

!Date class methodsFor: 'basic'!

dayOfWeek: dayName
    ^DayNameDict at: dayName asLowercase asSymbol
!

nameOfDay: dayIndex
    ^#(Monday Tuesday Wednesday Thursday Friday Saturday Sunday) at: dayIndex
!

indexOfMonth: monthName
    ^MonthNameDict at: monthName asLowercase asSymbol
!

nameOfMonth: monthIndex
    ^#(January February  March
       April   May       June
       July    August    September
       October November  December) at: monthIndex
!

daysInMonth: monthName forYear: yearInteger
    | monthIndex |
    monthIndex <- self indexOfMonth: monthName.
    ^self daysInMonthIndex: monthIndex forYear: yearInteger
!

daysInYear: yearInteger
    ^365 + (self leapYear: yearInteger)
!

leapYear: yearInteger
    (yearInteger \\ 4 = 0
        and: [ yearInteger \\ 100 ~= 0
            or: [ yearInteger \\ 400 = 0 ] ]) 
        ifTrue: [ ^1 ]
        ifFalse: [ ^0 ]
!

dateAndTimeNow
    ^Array with: (Date today) with: (Time now)
! !

!Date class methodsFor: 'instance creation'!

today
    | now date |
    now <- Time secondClock.
    date <- now // (24 * 60 * 60).
    ^self new setDays: date  + 25202 "(69 * 365 + 17)"
!

fromDays: dayCount
    ^self new setDays: dayCount
!

newDay: dayCount year: yearInteger
    ^self new setDays: (dayCount + self yearAsDays: yearInteger)
!

newDay: day month: monthName year: yearInteger
    ^self new setDays:
        (day + (self daysUntilMonth: monthName year: yearInteger)
             + (self yearAsDays: yearInteger))
! !

!Date class methodsFor: 'private methods'!

yearAsDays: yearInteger
    "Returns the number of days since Jan 1, 1901."
    yearInteger <- yearInteger - 1900.
    ^(yearInteger - 1) * 365
        + (yearInteger // 4)
        - (yearInteger // 100)
        + (yearInteger // 400)
!

daysUntilMonth: monthName year: yearInteger
    | monthIndex totalDays |
    totalDays <- 0.
    monthIndex <- self indexOfMonth: monthName.
    1 to: monthIndex - 1 do:
        [ :index | totalDays <- totalDays + (self daysInMonthIndex: index
                                                 forYear: yearInteger) ].
    ^totalDays
!


daysInMonthIndex: monthIndex forYear: yearInteger
    | days |
    days <- #(31 28 31           "Jan Feb Mar"
            30 31 30            "Apr May Jun"
            31 31 30            "Jul Aug Sep"
            31 30 31            "Oct Nov Dec"
            ) at: monthIndex.
    monthIndex = 2
        ifTrue: [ ^days + (self leapYear: yearInteger) ]
        ifFalse: [ ^days ]

! !

!Date methodsFor: 'basic'!

addDays: dayCount
    days <- days + dayCount
!

subtractDays: dayCount
    days <- days - dayCount
!

subtractDate: aDate
    ^days - aDate days
! !

!Date methodsFor: 'comparing'!

= aDate
    ^days = aDate days
!

< aDate
    ^days < aDate days
!

> aDate
    ^days > aDate days
!

<= aDate
    ^days <= aDate days
!

>= aDate
    ^days >= aDate days
!

hash
    ^days
! !

!Date methodsFor: 'printing'!

printOn: aStream
    self computeDateParts:
        [ :year :month :day |
            day printOn: aStream.
            aStream nextPut: $-;
                    nextPutAll: ((Date nameOfMonth: month) copyFrom: 1 to: 3);
                    nextPut: $-.
            year \\ 100 printOn: aStream ]
! !

!Date methodsFor: 'storing'!

storeOn: aStream
    "Won't work past around 1200 years in the future"
    aStream nextPut: $(.
    aStream nextPutAll: self classNameString.
    self computeDateParts:
        [ :year :month :day |
            aStream nextPutAll: ' newDay: ';
                store: day;
                nextPutAll: ' month: ';
                store: (Date nameOfMonth: month);
                nextPutAll: ' year: ';
                store: year ].
    aStream nextPut: $)
! !

!Date methodsFor: 'private methods'!

days
    ^days
!

setDays: dayCount
    days <- dayCount
!

computeDateParts: aBlock
    | yearInteger tempDays monthIndex daysInMonth |
    tempDays <- days - (days // 1460) "4*365"
                    + (days // 36500) "100*365"
                    - (days // 146000). "400*365"
    yearInteger <- tempDays // 365.
    "The +1 below makes tempDays be 1 based, instead of 0 based, so that the
     first day is 1 Jan 1901 instead of 0 jan 1901"
    tempDays <- days - (yearInteger * 365)
                    - (yearInteger // 4)
                    + (yearInteger // 100)
                    - (yearInteger // 400)
                    + 1.
    yearInteger <- yearInteger + 1901.
    monthIndex <- 1.
    [ monthIndex < 12
        and: [ daysInMonth <- Date daysInMonthIndex: monthIndex
                                  forYear: yearInteger.
               tempDays > daysInMonth ] ] whileTrue:
        [ monthIndex <- monthIndex + 1.
          tempDays <- tempDays - daysInMonth ].
    ^aBlock value: yearInteger value: monthIndex value: tempDays
! !

Magnitude subclass: 'Time'
          instanceVariableNames: 'seconds'
          classVariableNames: ''
          poolDictionaries: ''
          category: nil
!

Time comment: 
'My instances represent times of the day.  I provide methods for instance 
creation, methods that access components (hours, minutes, and seconds) of a 
time value, and a block execution timing facility.' !

!Time class methodsFor: 'basic'!

now
    ^self new setSeconds: Time secondClock
!

fromSeconds: secondCount
    ^self new setSeconds: (Time secondClock \\ (24*60*60)) + secondCount
!

millisecondClockValue
    ^self millisecondClock
!

millisecondsToRun: timedBlock
    | startTime|
    startTime <- self millisecondClock.
    timedBlock value.
    ^self millisecondClock - startTime
! !


!Time methodsFor: 'accessing'!

hours
    ^(seconds // (60*60)) \\ 24
!

minutes
    ^(seconds // 60) \\ 60
!

seconds
    ^seconds \\ 60
! !


!Time methodsFor: 'comparing'!
= aTime
    ^seconds = aTime time
!

< aTime
    ^seconds < aTime time
!

> aTime
    ^seconds > aTime time
!

<= aTime
    ^seconds <= aTime time
!

>= aTime
    ^seconds >= aTime time
!

hash
    ^seconds
! !


!Time methodsFor: 'arithmetic'!

addTime: timeAmount
    ^Time new setSeconds: seconds + timeAmount
!

subtractTime: timeAmount
    ^Time new setSeconds: seconds - timeAmount
!

printOn: aStream
    self hours printOn: aStream.
    aStream nextPut: $:.
    self minutes < 10 ifTrue: [ aStream nextPut: $0 ].
    self minutes printOn: aStream.
    aStream nextPut: $:.
    self seconds < 10 ifTrue: [ aStream nextPut: $0 ].
    self seconds printOn: aStream
! !

!Time methodsFor: 'private'!

setSeconds: secs
    seconds <- secs
!

time
    ^seconds
! !

!Time class methodsFor: 'builtins'!

secondClock
    <primitive: 98>
    ^self primitiveFailed
!

millisecondClock
    <primitive: 99>
   ^self primitiveFailed
! !

