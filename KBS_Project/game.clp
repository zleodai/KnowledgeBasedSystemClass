(deffacts start-game
   (boot))

(deffunction fatigue-name (?value)
   (if (= ?value 1) then (return "Well"))
   (if (= ?value 2) then (return "Slightly-Well"))
   (if (= ?value 3) then (return "Slightly-Tired"))
   (return "Tired"))

(deffunction health-name (?value)
   (if (= ?value 1) then (return "Good Health"))
   (if (= ?value 2) then (return "Mediocre Health"))
   (return "Poor Health"))

(deffunction action-banner (?title)
   (banner (str-cat "ACTION SELECTED: " ?title)))

(deffunction event-banner (?title)
   (banner (str-cat "EVENT: " ?title)))

(deffunction urgent-banner (?title)
   (banner (str-cat "URGENT: " ?title)))

(deffunction party-size ()
   (return (+ 1 (length$ ?*companion-names*))))

(deffunction set-starting-money (?role)
   (if (eq ?role banker) then
      (bind ?*money* 1600.0)
      (return))
   (if (eq ?role carpenter) then
      (bind ?*money* 800.0)
      (return))
   (bind ?*money* 400.0))

(deffunction choose-difficulty ()
   (banner "THE OREGON TRAIL - CLIPS EDITION")
   (printout t "Choose your starting profession. This only changes your starting money." crlf crlf)
   (printout t "1. Wealthy banker     $1600" crlf)
   (printout t "2. Middle-class carpenter $800" crlf)
   (printout t "3. Poor farmer        $400" crlf crlf)
   (bind ?chosen FALSE)
   (while (eq ?chosen FALSE) do
      (bind ?answer (prompt-lower "Type banker, carpenter, farmer, or 1/2/3: "))
      (if (or (eq ?answer "1") (eq ?answer "banker")) then
         (bind ?chosen banker))
      (if (or (eq ?answer "2") (eq ?answer "carpenter")) then
         (bind ?chosen carpenter))
      (if (or (eq ?answer "3") (eq ?answer "farmer")) then
         (bind ?chosen farmer))
      (if (eq ?chosen FALSE) then
         (printout t "Please choose one of the three professions." crlf)))
   (set-starting-money ?chosen)
   (printout t crlf "You begin as a " ?chosen " with $" ?*money* "." crlf))

(deffunction add-companion (?name)
   (bind ?*companion-names* (create$ ?*companion-names* ?name))
   (bind ?*companion-health* (create$ ?*companion-health* 1))
   (bind ?*companion-fatigue* (create$ ?*companion-fatigue* 1)))

(deffunction choose-companions ()
   (banner "NAME YOUR COMPANIONS")
   (printout t "Five companions will join you. Press Enter on any name to use a random one." crlf)
   (loop-for-count (?i 1 5) do
      (bind ?name (prompt-line (str-cat "Companion " ?i " name: ")))
      (if (eq ?name "") then
         (bind ?name (random-companion-name))
         (while (neq (member$ ?name ?*companion-names*) FALSE) do
            (bind ?name (random-companion-name)))
         (printout t "Generated name: " ?name crlf))
      (add-companion ?name))
   (printout t crlf "Your party has " (party-size) " people: you plus ")
   (loop-for-count (?i 1 (length$ ?*companion-names*)) do
      (printout t (nth$ ?i ?*companion-names*))
      (if (< ?i (length$ ?*companion-names*)) then
         (printout t ", ")))
   (printout t "." crlf))

(deffunction inventory-count (?item)
   (if (eq ?item oxen) then (return ?*oxen*))
   (if (eq ?item food) then (return ?*food*))
   (if (eq ?item water) then (return ?*water*))
   (if (eq ?item clothing) then (return ?*clothing*))
   (if (eq ?item bullets) then (return ?*bullets*))
   (if (eq ?item wheel) then (return ?*wagon-wheels*))
   (if (eq ?item axle) then (return ?*wagon-axles*))
   (if (eq ?item tongue) then (return ?*wagon-tongues*))
   (return 0))

(deffunction add-inventory (?item ?amount)
   (if (eq ?item oxen) then (bind ?*oxen* (+ ?*oxen* ?amount)))
   (if (eq ?item food) then (bind ?*food* (+ ?*food* ?amount)))
   (if (eq ?item water) then (bind ?*water* (+ ?*water* ?amount)))
   (if (eq ?item clothing) then (bind ?*clothing* (+ ?*clothing* ?amount)))
   (if (eq ?item bullets) then (bind ?*bullets* (+ ?*bullets* ?amount)))
   (if (eq ?item wheel) then (bind ?*wagon-wheels* (+ ?*wagon-wheels* ?amount)))
   (if (eq ?item axle) then (bind ?*wagon-axles* (+ ?*wagon-axles* ?amount)))
   (if (eq ?item tongue) then (bind ?*wagon-tongues* (+ ?*wagon-tongues* ?amount))))

(deffunction remove-inventory (?item ?amount)
   (if (> ?amount (inventory-count ?item)) then
      (return FALSE))
   (add-inventory ?item (- 0 ?amount))
   (return TRUE))

(deffunction print-item-line (?item)
   (printout t "  " (item-name-plural ?item) ": " (inventory-count ?item) crlf))

(deffunction show-inventory ()
   (banner "INVENTORY")
   (printout t "Money: $" ?*money* crlf)
   (print-item-line oxen)
   (print-item-line food)
   (print-item-line water)
   (print-item-line clothing)
   (print-item-line bullets)
   (print-item-line wheel)
   (print-item-line axle)
   (print-item-line tongue))

(deffunction show-party-status ()
   (banner "PARTY STATUS")
   (printout t "Trail Leader - " (health-name ?*leader-health*) ", " (fatigue-name ?*leader-fatigue*) crlf)
   (if (= (length$ ?*companion-names*) 0) then
      (printout t "No companions remain." crlf)
   else
      (loop-for-count (?i 1 (length$ ?*companion-names*)) do
         (printout t (nth$ ?i ?*companion-names*) " - "
                     (health-name (nth$ ?i ?*companion-health*)) ", "
                     (fatigue-name (nth$ ?i ?*companion-fatigue*)) crlf))))

(deffunction wagon-damaged ()
   (if (or (eq ?*wheel-ok* FALSE) (eq ?*axle-ok* FALSE) (eq ?*tongue-ok* FALSE)) then
      (return TRUE))
   (return FALSE))

(deffunction show-wagon-status ()
   (banner "WAGON STATUS")
   (printout t "Wheel: " (bool-word ?*wheel-ok*) crlf)
   (printout t "Axle:  " (bool-word ?*axle-ok*) crlf)
   (printout t "Tongue: " (bool-word ?*tongue-ok*) crlf)
   (if (wagon-damaged) then
      (printout t "A damaged wagon travels at half pace until repaired." crlf)
   else
      (printout t "The wagon is ready for regular travel." crlf)))

(deffunction show-shop-help ()
   (printout t crlf "Shop commands: oxen, food, water, clothing, bullets, wheel, axle, tongue, inventory, help, done" crlf)
   (printout t "Prices:" crlf)
   (printout t "  oxen: $40 per yoke of 2 oxen" crlf)
   (printout t "  food: $0.20 per lb" crlf)
   (printout t "  water: $0.05 per gallon" crlf)
   (printout t "  clothing: $10 per set" crlf)
   (printout t "  bullets: $2 per box" crlf)
   (printout t "  wheel/axle/tongue: $10 each" crlf))

(deffunction buy-item (?item)
   (bind ?amount (prompt-number (str-cat "How many " (item-name-plural ?item) " do you want to buy? ")))
   (if (<= ?amount 0) then
      (printout t "Purchase cancelled." crlf)
      (return))
   (bind ?cost (* ?amount (item-price ?item)))
   (if (> ?cost ?*money*) then
      (printout t "That costs $" ?cost ", but you only have $" ?*money* "." crlf)
      (return))
   (bind ?*money* (- ?*money* ?cost))
   (add-inventory ?item ?amount)
   (printout t "Bought " ?amount " " (item-name-plural ?item) " for $" ?cost ". Money left: $" ?*money* "." crlf))

(deffunction initial-shop ()
   (banner "MATT'S GENERAL STORE")
   (printout t "The shopkeeper recommends 200 lbs of food and 100 gallons of water per person." crlf)
   (printout t "For your party of " (party-size) ", that means " (* 200 (party-size)) " lbs of food and " (* 100 (party-size)) " gallons of water." crlf)
   (show-shop-help)
   (bind ?shopping TRUE)
   (while ?shopping do
      (printout t crlf "Money available: $" ?*money* crlf)
      (bind ?answer (prompt-lower "What would you like to buy? "))
      (if (eq ?answer "done") then
         (bind ?shopping FALSE)
      else
         (if (eq ?answer "inventory") then
            (show-inventory)
         else
            (if (eq ?answer "help") then
               (show-shop-help)
            else
               (bind ?item (parse-item ?answer))
               (if (eq ?item FALSE) then
                  (printout t "I do not sell that. Type help to see shop commands." crlf)
               else
                  (buy-item ?item))))))
   (printout t crlf "Your wagon rolls west from Independence." crlf))

(deffunction damage-amount (?fatigue)
   (if (= ?fatigue 4) then
      (return 2))
   (return 1))

(deffunction kill-companion-at (?index ?reason)
   (bind ?name (nth$ ?index ?*companion-names*))
   (bind ?*companion-names* (delete$ ?*companion-names* ?index ?index))
   (bind ?*companion-health* (delete$ ?*companion-health* ?index ?index))
   (bind ?*companion-fatigue* (delete$ ?*companion-fatigue* ?index ?index))
   (printout t ?name " has died " ?reason "." crlf))

(deffunction random-companion-death (?reason)
   (if (= (length$ ?*companion-names*) 0) then
      (bind ?*game-over* TRUE)
      (printout t "You have died " ?reason "." crlf)
      (return))
   (kill-companion-at (random 1 (length$ ?*companion-names*)) ?reason))

(deffunction injure-leader (?amount ?reason)
   (bind ?*leader-health* (+ ?*leader-health* ?amount))
   (if (> ?*leader-health* 3) then
      (bind ?*game-over* TRUE)
      (printout t "Your health collapsed " ?reason ". You have died." crlf)
   else
      (printout t "Your health is now " (health-name ?*leader-health*) "." crlf)))

(deffunction injure-companion (?index ?amount ?reason)
   (bind ?new-health (+ (nth$ ?index ?*companion-health*) ?amount))
   (if (> ?new-health 3) then
      (kill-companion-at ?index ?reason)
   else
      (bind ?*companion-health* (replace$ ?*companion-health* ?index ?index ?new-health))
      (printout t (nth$ ?index ?*companion-names*) " is now " (health-name ?new-health) "." crlf)))

(deffunction harm-party (?reason)
   (injure-leader (damage-amount ?*leader-fatigue*) ?reason)
   (bind ?i 1)
   (while (and (not ?*game-over*) (<= ?i (length$ ?*companion-names*))) do
      (bind ?fatigue (nth$ ?i ?*companion-fatigue*))
      (bind ?before (length$ ?*companion-names*))
      (injure-companion ?i (damage-amount ?fatigue) ?reason)
      (if (= ?before (length$ ?*companion-names*)) then
         (bind ?i (+ ?i 1)))))

(deffunction expose-travelers-to-snowstorm (?missing)
   (printout t "You are missing " ?missing " set")
   (if (neq ?missing 1) then
      (printout t "s"))
   (printout t " of clothing, so " ?missing " traveler")
   (if (neq ?missing 1) then
      (printout t "s are")
   else
      (printout t " is"))
   (printout t " exposed to the cold." crlf)
   (bind ?remaining ?missing)
   (bind ?i 1)
   (while (and (not ?*game-over*) (> ?remaining 0) (<= ?i (length$ ?*companion-names*))) do
      (bind ?fatigue (nth$ ?i ?*companion-fatigue*))
      (bind ?before (length$ ?*companion-names*))
      (injure-companion ?i (damage-amount ?fatigue) "from exposure in the snowstorm")
      (bind ?remaining (- ?remaining 1))
      (if (= ?before (length$ ?*companion-names*)) then
         (bind ?i (+ ?i 1))))
   (if (and (not ?*game-over*) (> ?remaining 0)) then
      (injure-leader (damage-amount ?*leader-fatigue*) "from exposure in the snowstorm")))

(deffunction improve-party-rest ()
   (bind ?*leader-fatigue* 1)
   (if (> ?*leader-health* 1) then
      (bind ?*leader-health* (- ?*leader-health* 1)))
   (loop-for-count (?i 1 (length$ ?*companion-names*)) do
      (bind ?health (nth$ ?i ?*companion-health*))
      (bind ?*companion-fatigue* (replace$ ?*companion-fatigue* ?i ?i 1))
      (if (> ?health 1) then
         (bind ?*companion-health* (replace$ ?*companion-health* ?i ?i (- ?health 1)))))
   (printout t "The party rests. Everyone's fatigue returns to Well, and injuries move one step toward recovery." crlf))

(deffunction add-fatigue-after-travel ()
   (if (< ?*leader-fatigue* 4) then
      (bind ?*leader-fatigue* (+ ?*leader-fatigue* 1)))
   (loop-for-count (?i 1 (length$ ?*companion-names*)) do
      (bind ?fatigue (nth$ ?i ?*companion-fatigue*))
      (if (< ?fatigue 4) then
         (bind ?*companion-fatigue* (replace$ ?*companion-fatigue* ?i ?i (+ ?fatigue 1))))))

(deffunction break-wagon-part (?part)
   (if (eq ?part wheel) then
      (bind ?*wheel-ok* FALSE)
      (printout t "The wagon wheel is broken." crlf))
   (if (eq ?part axle) then
      (bind ?*axle-ok* FALSE)
      (printout t "The wagon axle is broken." crlf))
   (if (eq ?part tongue) then
      (bind ?*tongue-ok* FALSE)
      (printout t "The wagon tongue is broken." crlf)))

(deffunction random-repair-part ()
   (return (choose-random (create$ wheel axle tongue))))

(deffunction random-supply-loss ()
   (bind ?choice (random 1 2))
   (if (= ?choice 1) then
      (if (> ?*bullets* 0) then
         (remove-inventory bullets 1)
         (printout t "A box of bullets fell from the wagon." crlf)
      else
         (printout t "A box of bullets nearly fell, but you had none to lose." crlf))
      (return))
   (bind ?parts (create$))
   (if (> ?*wagon-wheels* 0) then (bind ?parts (create$ ?parts wheel)))
   (if (> ?*wagon-axles* 0) then (bind ?parts (create$ ?parts axle)))
   (if (> ?*wagon-tongues* 0) then (bind ?parts (create$ ?parts tongue)))
   (if (= (length$ ?parts) 0) then
      (printout t "A spare wagon part nearly fell, but you had none to lose." crlf)
   else
      (bind ?part (choose-random ?parts))
      (remove-inventory ?part 1)
      (printout t "A spare " (item-name ?part) " fell from the wagon." crlf)))

(deffunction native-attack-event ()
   (event-banner "NATIVE ATTACK")
   (printout t "A Native attack scatters supplies." crlf)
   (bind ?loss 10)
   (if (< ?*food* ?loss) then
      (bind ?loss ?*food*))
   (bind ?*food* (- ?*food* ?loss))
   (printout t "You lose " ?loss " lbs of food." crlf))

(deffunction wild-animal-event ()
   (event-banner "WILD ANIMAL ATTACK")
   (printout t "Wild animals attack the camp." crlf)
   (if (> ?*bullets* 0) then
      (bind ?answer (prompt-lower "Use 1 box of bullets to drive them away? (yes/no): "))
      (if (yes-answer ?answer) then
         (remove-inventory bullets 1)
         (printout t "The animals scatter. One box of bullets is gone." crlf)
         (return)))
   (printout t "Without ammunition, the party is hurt." crlf)
   (harm-party "after the wild animal attack"))

(deffunction snowstorm-event ()
   (event-banner "SNOWSTORM")
   (printout t "A snowstorm strikes." crlf)
   (if (< ?*clothing* (party-size)) then
      (printout t "You do not have enough clothing for everyone." crlf)
      (expose-travelers-to-snowstorm (- (party-size) ?*clothing*))
   else
      (printout t "Your clothing protects the party." crlf)))

(deffunction heat-event ()
   (event-banner "EXTREME HEAT")
   (printout t "Extreme heat bears down on the trail." crlf)
   (bind ?*extra-water-today* (+ ?*extra-water-today* 1.0))
   (printout t "The party must drink 1 extra gallon of water today." crlf))

(deffunction helpful-traveler-event ()
   (event-banner "HELPFUL TRAVELER")
   (printout t "A helpful traveler shares supplies." crlf)
   (bind ?*food* (+ ?*food* 5))
   (printout t "You receive 5 lbs of food." crlf))

(deffunction supplies-fall-event ()
   (event-banner "SUPPLIES FALL OFF THE WAGON")
   (printout t "Supplies fall off the wagon." crlf)
   (random-supply-loss))

(deffunction random-travel-event ()
   (if (> (random 1 100) 50) then
      (printout t "No random event today." crlf)
      (return))
   (bind ?roll (random 1 100))
   (if (<= ?roll 10) then (native-attack-event) (return))
   (if (<= ?roll 20) then (wild-animal-event) (return))
   (if (<= ?roll 30) then (snowstorm-event) (return))
   (if (<= ?roll 45) then (heat-event) (return))
   (if (<= ?roll 50) then (event-banner "AXLE BREAKS") (printout t "The axle breaks." crlf) (break-wagon-part axle) (return))
   (if (<= ?roll 55) then (event-banner "WHEEL BREAKS") (printout t "The wheel breaks." crlf) (break-wagon-part wheel) (return))
   (if (<= ?roll 60) then (event-banner "WAGON TONGUE BREAKS") (printout t "The wagon tongue breaks." crlf) (break-wagon-part tongue) (return))
   (if (<= ?roll 85) then (helpful-traveler-event) (return))
   (supplies-fall-event))

(deffunction river-crossing-event ()
   (printout t "This river crossing may cost supplies." crlf)
   (if (> (random 1 100) 50) then
      (printout t "The crossing is tense, but nothing is lost." crlf)
      (return))
   (bind ?roll (random 1 100))
   (if (<= ?roll 30) then
      (if (> ?*bullets* 0) then
         (remove-inventory bullets 1)
         (printout t "A box of bullets is lost in the river." crlf)
      else
         (printout t "The river tries to take ammunition, but you have none." crlf))
      (return))
   (if (<= ?roll 80) then
      (if (> ?*food* 0) then
         (remove-inventory food 1)
         (printout t "1 lb of food is ruined by river water." crlf)
      else
         (printout t "The river ruins no food because none remains." crlf))
      (return))
   (bind ?parts (create$))
   (if (> ?*wagon-wheels* 0) then (bind ?parts (create$ ?parts wheel)))
   (if (> ?*wagon-axles* 0) then (bind ?parts (create$ ?parts axle)))
   (if (> ?*wagon-tongues* 0) then (bind ?parts (create$ ?parts tongue)))
   (if (= (length$ ?parts) 0) then
      (printout t "A repair kit would have been lost, but you have none." crlf)
   else
      (bind ?part (choose-random ?parts))
      (remove-inventory ?part 1)
      (printout t "A spare " (item-name ?part) " is lost in the river." crlf)))

(deffunction dangerous-terrain-event ()
   (printout t "The terrain is dangerous for the wagon." crlf)
   (if (<= (random 1 100) 50) then
      (break-wagon-part (random-repair-part))
   else
      (printout t "The wagon survives the crossing intact." crlf)))

(deffunction location-event ()
   (banner (str-cat "LOCATION EVENT: " (location-name ?*location-index*)))
   (printout t "You have arrived at " (location-name ?*location-index*) "." crlf)
   (bind ?type (location-type ?*location-index*))
   (if (eq ?type fort) then
      (printout t "This fort is a good place to trade. Local offers here are better than usual." crlf))
   (if (eq ?type river) then
      (river-crossing-event))
   (if (eq ?type landmark) then
      (printout t (landmark-description ?*location-index*) crlf))
   (if (eq ?type dangerous) then
      (dangerous-terrain-event))
   (if (eq ?type end) then
      (printout t "The Willamette Valley opens before you. Keep everyone alive through the end of the day to win." crlf)))

(deffunction advance-location-if-needed ()
   (if (> ?*days-to-next* 0) then
      (return))
   (bind ?*location-index* (+ ?*location-index* 1))
   (if (< ?*location-index* (location-count)) then
      (bind ?*days-to-next* 8.0)
   else
      (bind ?*days-to-next* 0.0))
   (location-event))

(deffunction travel-day ()
   (bind ?*traveled-today* TRUE)
   (if (wagon-damaged) then
      (bind ?pace 0.5)
      (printout t "Because a wagon part is broken, you travel only half a day's distance." crlf)
   else
      (bind ?pace 1.0)
      (printout t "You travel for the whole day." crlf))
   (bind ?*days-to-next* (- ?*days-to-next* ?pace))
   (if (< ?*days-to-next* 0) then
      (bind ?*days-to-next* 0))
   (random-travel-event)
   (advance-location-if-needed))

(deffunction trade-quantity (?item)
   (if (eq ?item oxen) then (return 1))
   (if (eq ?item food) then (return (* (random 1 12) 5)))
   (if (eq ?item water) then (return (* (random 1 16) 5)))
   (if (eq ?item clothing) then (return (random 1 3)))
   (if (eq ?item bullets) then (return (random 1 8)))
   (return (random 1 3)))

(deffunction make-trade (?fort)
   (bind ?items (trade-items))
   (bind ?valid FALSE)
   (while (eq ?valid FALSE) do
      (bind ?offer-item (choose-random ?items))
      (bind ?request-item (choose-random ?items))
      (while (eq ?offer-item ?request-item) do
         (bind ?request-item (choose-random ?items)))
      (bind ?offer-qty (trade-quantity ?offer-item))
      (bind ?request-qty (trade-quantity ?request-item))
      (bind ?offer-value (* ?offer-qty (item-price ?offer-item)))
      (bind ?request-value (* ?request-qty (item-price ?request-item)))
      (bind ?gain (- ?offer-value ?request-value))
      (if ?fort then
         (if (and (>= ?gain 0) (<= ?gain 10)) then
            (bind ?valid TRUE))
      else
         (if (and (>= ?gain -10) (<= ?gain 10)) then
            (bind ?valid TRUE))))
   (return (create$ ?offer-item ?offer-qty ?request-item ?request-qty ?gain)))

(deffunction show-trade (?trade)
   (bind ?offer-item (nth$ 1 ?trade))
   (bind ?offer-qty (nth$ 2 ?trade))
   (bind ?request-item (nth$ 3 ?trade))
   (bind ?request-qty (nth$ 4 ?trade))
   (printout t crlf "A local offers " ?offer-qty " " (item-name-plural ?offer-item)
              " for " ?request-qty " " (item-name-plural ?request-item) "." crlf))

(deffunction accept-trade (?trade)
   (bind ?offer-item (nth$ 1 ?trade))
   (bind ?offer-qty (nth$ 2 ?trade))
   (bind ?request-item (nth$ 3 ?trade))
   (bind ?request-qty (nth$ 4 ?trade))
   (if (< (inventory-count ?request-item) ?request-qty) then
      (printout t "You do not have enough " (item-name-plural ?request-item) " for that trade." crlf)
      (return FALSE))
   (remove-inventory ?request-item ?request-qty)
   (add-inventory ?offer-item ?offer-qty)
   (printout t "Trade accepted." crlf)
   (return TRUE))

(deffunction trade-day ()
   (bind ?fort (eq (location-type ?*location-index*) fort))
   (if ?fort then
      (printout t "You are trading at a fort. Offers will favor you by up to $10." crlf)
   else
      (printout t "You trade with locals near the trail. Offers may be fair or unfair." crlf))
   (bind ?done FALSE)
   (while (eq ?done FALSE) do
      (bind ?trade (make-trade ?fort))
      (show-trade ?trade)
      (printout t "Commands: accept, skip, done" crlf)
      (bind ?answer (prompt-lower "Your choice: "))
      (if (eq ?answer "accept") then
         (accept-trade ?trade))
      (if (eq ?answer "done") then
         (bind ?done TRUE))
      (if (and (neq ?answer "accept") (neq ?answer "skip") (neq ?answer "done")) then
         (printout t "Unknown trade command. Showing another offer." crlf)))
   (printout t "Trading takes the rest of the day." crlf))

(deffunction part-ok (?part)
   (if (eq ?part wheel) then (return ?*wheel-ok*))
   (if (eq ?part axle) then (return ?*axle-ok*))
   (if (eq ?part tongue) then (return ?*tongue-ok*))
   (return TRUE))

(deffunction set-part-ok (?part)
   (if (eq ?part wheel) then (bind ?*wheel-ok* TRUE))
   (if (eq ?part axle) then (bind ?*axle-ok* TRUE))
   (if (eq ?part tongue) then (bind ?*tongue-ok* TRUE)))

(deffunction repair-day ()
   (show-wagon-status)
   (bind ?part (parse-part (prompt-lower "Which part do you want to repair? Type wheel, axle, tongue, or cancel: ")))
   (if (eq ?part FALSE) then
      (printout t "Repair cancelled. Returning to the start-of-day menu." crlf)
      (return FALSE))
   (if (part-ok ?part) then
      (printout t "The " (item-name ?part) " is not broken. Returning to the start-of-day menu." crlf)
      (return FALSE))
   (if (<= (inventory-count ?part) 0) then
      (urgent-banner "WAGON REPAIR FAILED")
      (printout t "MISSING PART: You have 0 spare " (item-name-plural ?part) "." crlf)
      (printout t "BROKEN PART: The " (item-name ?part) " is still broken." crlf)
      (printout t "TRAVEL WARNING: Your wagon will keep moving at half pace until this is fixed." crlf)
      (printout t "WHAT YOU NEED: Buy or trade for 1 spare " (item-name ?part) ", then choose repair again." crlf)
      (printout t "No day was spent. Returning to the start-of-day menu." crlf)
      (return FALSE))
   (remove-inventory ?part 1)
   (set-part-ok ?part)
   (printout t "You spend the day repairing the " (item-name ?part) "." crlf)
   (return TRUE))

(deffunction consume-food ()
   (if (< ?*food* 1) then
      (bind ?*game-over* TRUE)
      (printout t "There is not enough food for you. You starve." crlf)
      (return))
   (while (and (< ?*food* (party-size)) (> (length$ ?*companion-names*) 0)) do
      (random-companion-death "from starvation"))
   (if ?*game-over* then
      (return))
   (bind ?need (party-size))
   (if (> ?need ?*food*) then
      (bind ?*food* 0)
   else
      (bind ?*food* (- ?*food* ?need)))
   (printout t "The party eats " ?need " lbs of food." crlf))

(deffunction consume-water ()
   (bind ?need (+ (* (party-size) 0.5) ?*extra-water-today*))
   (if (< ?*water* 0.5) then
      (bind ?*game-over* TRUE)
      (printout t "There is not enough water for you. You die of thirst." crlf)
      (return))
   (while (and (< ?*water* (+ (* (party-size) 0.5) ?*extra-water-today*))
               (> (length$ ?*companion-names*) 0)) do
      (random-companion-death "from dehydration"))
   (if ?*game-over* then
      (return))
   (bind ?need (+ (* (party-size) 0.5) ?*extra-water-today*))
   (if (< ?*water* ?need) then
      (bind ?*game-over* TRUE)
      (printout t "There is not enough water for the extra heat ration. You die of thirst." crlf)
      (return))
   (if (> ?need ?*water*) then
      (bind ?*water* 0)
   else
      (bind ?*water* (- ?*water* ?need)))
   (printout t "The party drinks " ?need " gallons of water." crlf))

(deffunction end-day ()
   (banner (str-cat "DAY " ?*day* " ENDS"))
   (consume-food)
   (if (not ?*game-over*) then
      (consume-water))
   (if (and (not ?*game-over*) ?*traveled-today*) then
      (add-fatigue-after-travel)
      (printout t "Travel fatigue increases for everyone." crlf))
   (if (and (not ?*game-over*) (= ?*location-index* (location-count))) then
      (bind ?*won* TRUE)
      (bind ?*game-over* TRUE))
   (bind ?*extra-water-today* 0.0)
   (bind ?*traveled-today* FALSE)
   (bind ?*day* (+ ?*day* 1)))

(deffunction show-day-menu ()
   (banner (str-cat "DAY " ?*day* " - " (location-name ?*location-index*)))
   (if (< ?*location-index* (location-count)) then
      (printout t "Next location: " (location-name (+ ?*location-index* 1)) crlf)
      (printout t "Distance: " ?*days-to-next* " travel-days away at normal pace." crlf))
   (if (wagon-damaged) then
      (printout t "Warning: A damaged wagon moves at half pace. One travel day only counts as 0.5 days of progress." crlf))
   (printout t crlf "Commands you can type:" crlf)
   (printout t "  travel    - spend the day traveling toward the next location" crlf)
   (printout t "  rest      - spend the day resting; no random or location events occur" crlf)
   (printout t "  trade     - spend the day trading with locals" crlf)
   (printout t "  repair    - repair a broken wagon part if you have the spare part" crlf)
   (printout t "  inventory - check supplies without spending the day" crlf)
   (printout t "  party     - check health and fatigue without spending the day" crlf)
   (printout t "  wagon     - check wagon damage without spending the day" crlf)
   (printout t "  quit      - end the game" crlf))

(deffunction take-day-action ()
   (bind ?spent FALSE)
   (while (and (not ?spent) (not ?*game-over*)) do
      (show-day-menu)
      (bind ?answer (prompt-lower "What will you do today? "))
      (if (eq ?answer "inventory") then
         (show-inventory))
      (if (eq ?answer "party") then
         (show-party-status))
      (if (eq ?answer "wagon") then
         (show-wagon-status))
      (if (eq ?answer "travel") then
         (action-banner "TRAVEL")
         (travel-day)
         (bind ?spent TRUE))
      (if (eq ?answer "rest") then
         (action-banner "REST")
         (improve-party-rest)
         (bind ?spent TRUE))
      (if (eq ?answer "trade") then
         (action-banner "TRADE")
         (trade-day)
         (bind ?spent TRUE))
      (if (eq ?answer "repair") then
         (action-banner "REPAIR WAGON")
         (bind ?spent (repair-day)))
      (if (eq ?answer "quit") then
         (action-banner "QUIT")
         (bind ?*game-over* TRUE)
         (printout t "You turn back from the trail." crlf))
      (if (and (not ?spent)
               (not ?*game-over*)
               (neq ?answer "inventory")
               (neq ?answer "party")
               (neq ?answer "wagon")
               (neq ?answer "repair")) then
         (printout t "Please type one of the listed commands." crlf)))
   (if (and ?spent (not ?*game-over*)) then
      (end-day)))

(deffunction play-game ()
   (choose-difficulty)
   (choose-companions)
   (initial-shop)
   (while (not ?*game-over*) do
      (take-day-action))
   (banner "GAME OVER")
   (if ?*won* then
      (printout t "You reached the Willamette Valley alive. You win!" crlf)
   else
      (printout t "Your journey has ended before reaching the Willamette Valley." crlf))
   (bind ?final-day (- ?*day* 1))
   (if (< ?final-day 1) then
      (bind ?final-day 1))
   (printout t "Final day: " ?final-day crlf)
   (printout t "Final location: " (location-name ?*location-index*) crlf)
   (show-inventory)
   (show-party-status)
   (show-wagon-status))

(defrule execution
   ?b <- (boot)
   =>
   (retract ?b)
   (play-game))
