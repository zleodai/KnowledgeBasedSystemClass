(deftemplate node
   (slot id)
   (slot type)
   (slot attribute)
   (slot conclusion))

(deftemplate branch
   (slot from)
   (slot answer)
   (slot to))

(deftemplate root
   (slot id))

(deftemplate decision
   (slot conclusion))

(deftemplate path-state
   (slot current-node)
   (multislot conditions))

;; insert decision tree here (this case being the animal tree from figure 3.3)
(deffacts decision-tree
   (root (id n1))

   (node (id n1) (type internal) (attribute big))
   (node (id n2) (type internal) (attribute squeak))
   (node (id n3) (type internal) (attribute long_neck))
   (node (id n4) (type internal) (attribute trunk))
   (node (id n5) (type internal) (attribute like_water))

   (node (id n6) (type leaf) (conclusion squirrel))
   (node (id n7) (type leaf) (conclusion mouse))
   (node (id n8) (type leaf) (conclusion giraffe))
   (node (id n9) (type leaf) (conclusion elephant))
   (node (id n10) (type leaf) (conclusion rhino))
   (node (id n11) (type leaf) (conclusion hippo))

   (branch (from n1) (answer yes) (to n3))
   (branch (from n1) (answer no)  (to n2))
   (branch (from n2) (answer yes) (to n7))
   (branch (from n2) (answer no)  (to n6))
   (branch (from n3) (answer yes) (to n8))
   (branch (from n3) (answer no)  (to n4))
   (branch (from n4) (answer yes) (to n9))
   (branch (from n4) (answer no)  (to n5))
   (branch (from n5) (answer yes) (to n11))
   (branch (from n5) (answer no)  (to n10))
)

(defrule initialize-traversal
   (root (id ?rid))
   =>
   (assert (path-state (current-node ?rid) (conditions)))
)

(defrule expand-branch
   ?p <- (path-state (current-node ?nid) (conditions $?conds))
   (node (id ?nid) (type internal) (attribute ?attr))
   (branch (from ?nid) (answer yes) (to ?yes))
   (branch (from ?nid) (answer no)  (to ?no))
   =>
   (assert (path-state (current-node ?yes) (conditions $?conds ?attr yes)))
   (assert (path-state (current-node ?no)  (conditions $?conds ?attr no)))
   (retract ?p)
)

(deffunction print-conditions (?conds)
   (bind ?len (length$ ?conds))
   (if (= ?len 0) then (return "TRUE"))
   (bind ?i 1)
   (while (<= ?i ?len) do
      (printout t "  (" (nth$ ?i ?conds) " " (nth$ (+ ?i 1) ?conds) ")" crlf)
      (bind ?i (+ ?i 2))
   )
)

(defrule print-if-statement
   ?p <- (path-state (current-node ?nid) (conditions $?conds))
   (node (id ?nid) (type leaf) (conclusion ?conc))
   =>
   (bind ?rname (sym-cat rule- ?conc))
   
   (printout t crlf
      "(defrule " ?rname crlf)
   (print-conditions ?conds)
   (printout t "  =>" crlf "  (guess (" ?conc ")))" crlf)
)