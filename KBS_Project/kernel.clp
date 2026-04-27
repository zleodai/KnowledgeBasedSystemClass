(deffunction banner (?title)
   (printout t crlf "==================================================" crlf)
   (printout t ?title crlf)
   (printout t "==================================================" crlf))

(deffunction prompt-line (?prompt)
   (printout t ?prompt)
   (return (readline)))

(deffunction prompt-lower (?prompt)
   (return (lowcase (prompt-line ?prompt))))

(deffunction parse-number (?value)
   (if (eq ?value "") then
      (return FALSE))
   (bind ?field (string-to-field ?value))
   (if (numberp ?field) then
      (return ?field))
   (return FALSE))

(deffunction prompt-number (?prompt)
   (bind ?answer FALSE)
   (while (eq ?answer FALSE) do
      (bind ?raw (prompt-line ?prompt))
      (bind ?answer (parse-number ?raw))
      (if (eq ?answer FALSE) then
         (printout t "Please enter a number." crlf)))
   (return ?answer))

(deffunction yes-answer (?answer)
   (bind ?clean (lowcase ?answer))
   (if (or (eq ?clean "y") (eq ?clean "yes")) then
      (return TRUE))
   (return FALSE))

(deffunction random-index (?items)
   (return (random 1 (length$ ?items))))

(deffunction choose-random (?items)
   (return (nth$ (random-index ?items) ?items)))

(deffunction clamp-low (?value ?minimum)
   (if (< ?value ?minimum) then
      (return ?minimum))
   (return ?value))

(deffunction clamp-high (?value ?maximum)
   (if (> ?value ?maximum) then
      (return ?maximum))
   (return ?value))

(deffunction bool-word (?value)
   (if (eq ?value TRUE) then
      (return "OK"))
   (return "BROKEN"))
