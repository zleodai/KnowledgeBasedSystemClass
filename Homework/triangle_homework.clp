(clear)

(dribble-on "triangle_dribble_output.txt")

(deftemplate triangle
   (slot id)
   (slot label)
   (slot x1)
   (slot y1)
   (slot x2)
   (slot y2)
   (slot x3)
   (slot y3))

(deftemplate next-triangle
   (slot id))

(deffunction square (?n)
   (* ?n ?n))

(deffunction distance (?x1 ?y1 ?x2 ?y2)
   (sqrt (+ (square (- ?x2 ?x1))
            (square (- ?y2 ?y1)))))

(deffunction close-enough (?side-a ?side-b)
   (< (abs (- ?side-a ?side-b)) 0.00001))

(deffunction coordinates-are-numbers (?x1 ?y1 ?x2 ?y2 ?x3 ?y3)
   (and (numberp ?x1)
        (numberp ?y1)
        (numberp ?x2)
        (numberp ?y2)
        (numberp ?x3)
        (numberp ?y3)))

(deffacts test-triangles
   (next-triangle (id 1))
   (triangle (id 1)
             (label "a")
             (x1 0) (y1 0)
             (x2 2) (y2 4)
             (x3 6) (y3 0))
   (triangle (id 2)
             (label "b")
             (x1 1) (y1 2)
             (x2 4) (y2 5)
             (x3 7) (y3 2))
   (triangle (id 3)
             (label "c")
             (x1 0) (y1 0)
             (x2 3) (y2 5.196152)
             (x3 6.0) (y3 0)))

(defrule reject-nonnumeric-triangle
   ?step <- (next-triangle (id ?id))
   (triangle (id ?id)
             (label ?label)
             (x1 ?x1) (y1 ?y1)
             (x2 ?x2) (y2 ?y2)
             (x3 ?x3) (y3 ?y3))
   (test (not (coordinates-are-numbers ?x1 ?y1 ?x2 ?y2 ?x3 ?y3)))
   =>
   (printout t "Triangle " ?label
               ": ERROR - all point coordinates must be numbers." crlf)
   (retract ?step)
   (assert (next-triangle (id (+ ?id 1)))))

(defrule classify-triangle
   ?step <- (next-triangle (id ?id))
   (triangle (id ?id)
             (label ?label)
             (x1 ?x1) (y1 ?y1)
             (x2 ?x2) (y2 ?y2)
             (x3 ?x3) (y3 ?y3))
   (test (coordinates-are-numbers ?x1 ?y1 ?x2 ?y2 ?x3 ?y3))
   =>
   (bind ?side12 (distance ?x1 ?y1 ?x2 ?y2))
   (bind ?side23 (distance ?x2 ?y2 ?x3 ?y3))
   (bind ?side31 (distance ?x3 ?y3 ?x1 ?y1))
   (bind ?side12-side23-equal (close-enough ?side12 ?side23))
   (bind ?side23-side31-equal (close-enough ?side23 ?side31))
   (bind ?side31-side12-equal (close-enough ?side31 ?side12))
   (if (and ?side12-side23-equal
            ?side23-side31-equal
            ?side31-side12-equal)
      then
      (bind ?triangle-type "equilateral")
      else
      (if (or ?side12-side23-equal
              ?side23-side31-equal
              ?side31-side12-equal)
         then
         (bind ?triangle-type "isosceles")
         else
         (bind ?triangle-type "scalene")))
   (printout t "Triangle " ?label ": points ("
               ?x1 ", " ?y1 "), ("
               ?x2 ", " ?y2 "), and ("
               ?x3 ", " ?y3 ")" crlf)
   (printout t "   side lengths: "
               ?side12 ", " ?side23 ", " ?side31 crlf)
   (printout t "   type: " ?triangle-type crlf crlf)
   (retract ?step)
   (assert (next-triangle (id (+ ?id 1)))))

(reset)
(run)

(dribble-off)