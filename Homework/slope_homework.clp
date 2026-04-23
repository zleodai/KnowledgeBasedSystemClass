(clear)

(dribble-on "slope_dribble_output.txt")

(deftemplate line
   (slot id)
   (slot label)
   (slot x1)
   (slot y1)
   (slot x2)
   (slot y2))

(deftemplate next-line
   (slot id))

(deffunction coordinates-are-numbers (?x1 ?y1 ?x2 ?y2)
   (and (numberp ?x1)
        (numberp ?y1)
        (numberp ?x2)
        (numberp ?y2)))

(deffacts test-lines
   (next-line (id 1))
   (line (id 1)
         (label "regular finite slope")
         (x1 1) (y1 2)
         (x2 5) (y2 8))
   (line (id 2)
         (label "horizontal line")
         (x1 -3) (y1 5)
         (x2 6) (y2 5))
   (line (id 3)
         (label "vertical line")
         (x1 2) (y1 -1)
         (x2 2) (y2 7))
   (line (id 4)
         (label "duplicate point")
         (x1 4) (y1 4)
         (x2 4) (y2 4))
   (line (id 5)
         (label "nonnumeric coordinate")
         (x1 a) (y1 1)
         (x2 3) (y2 7)))

(defrule reject-nonnumeric-coordinates
   ?step <- (next-line (id ?id))
   (line (id ?id)
         (label ?label)
         (x1 ?x1) (y1 ?y1)
         (x2 ?x2) (y2 ?y2))
   (test (not (coordinates-are-numbers ?x1 ?y1 ?x2 ?y2)))
   =>
   (printout t "Test " ?id " - " ?label
               ": ERROR - all coordinates must be numbers. Received ("
               ?x1 ", " ?y1 ") and (" ?x2 ", " ?y2 ")." crlf)
   (retract ?step)
   (assert (next-line (id (+ ?id 1)))))

(defrule reject-duplicate-points
   ?step <- (next-line (id ?id))
   (line (id ?id)
         (label ?label)
         (x1 ?x1) (y1 ?y1)
         (x2 ?x2) (y2 ?y2))
   (test (coordinates-are-numbers ?x1 ?y1 ?x2 ?y2))
   (test (and (= ?x1 ?x2) (= ?y1 ?y2)))
   =>
   (printout t "Test " ?id " - " ?label
               ": ERROR - the same point was provided twice: ("
               ?x1 ", " ?y1 ")." crlf)
   (retract ?step)
   (assert (next-line (id (+ ?id 1)))))

(defrule report-vertical-line
   ?step <- (next-line (id ?id))
   (line (id ?id)
         (label ?label)
         (x1 ?x1) (y1 ?y1)
         (x2 ?x2) (y2 ?y2))
   (test (coordinates-are-numbers ?x1 ?y1 ?x2 ?y2))
   (test (and (= ?x1 ?x2) (<> ?y1 ?y2)))
   =>
   (printout t "Test " ?id " - " ?label
               ": points (" ?x1 ", " ?y1 ") and ("
               ?x2 ", " ?y2 ") -> slope = infinite" crlf)
   (retract ?step)
   (assert (next-line (id (+ ?id 1)))))

(defrule report-horizontal-line
   ?step <- (next-line (id ?id))
   (line (id ?id)
         (label ?label)
         (x1 ?x1) (y1 ?y1)
         (x2 ?x2) (y2 ?y2))
   (test (coordinates-are-numbers ?x1 ?y1 ?x2 ?y2))
   (test (and (<> ?x1 ?x2) (= ?y1 ?y2)))
   =>
   (printout t "Test " ?id " - " ?label
               ": points (" ?x1 ", " ?y1 ") and ("
               ?x2 ", " ?y2 ") -> slope = 0" crlf)
   (retract ?step)
   (assert (next-line (id (+ ?id 1)))))

(defrule report-finite-slope
   ?step <- (next-line (id ?id))
   (line (id ?id)
         (label ?label)
         (x1 ?x1) (y1 ?y1)
         (x2 ?x2) (y2 ?y2))
   (test (coordinates-are-numbers ?x1 ?y1 ?x2 ?y2))
   (test (and (<> ?x1 ?x2) (<> ?y1 ?y2)))
   =>
   (bind ?slope (/ (- ?y2 ?y1) (- ?x2 ?x1)))
   (printout t "Test " ?id " - " ?label
               ": points (" ?x1 ", " ?y1 ") and ("
               ?x2 ", " ?y2 ") -> slope = " ?slope crlf)
   (retract ?step)
   (assert (next-line (id (+ ?id 1)))))

(printout t "Slope calculation tests" crlf crlf)
(reset)
(run)

(dribble-off)
