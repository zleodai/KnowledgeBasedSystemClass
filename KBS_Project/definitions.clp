(defglobal
   ?*game-over* = FALSE
   ?*won* = FALSE
   ?*day* = 1
   ?*money* = 0.0
   ?*leader-health* = 1
   ?*leader-fatigue* = 1
   ?*companion-names* = (create$)
   ?*companion-health* = (create$)
   ?*companion-fatigue* = (create$)
   ?*oxen* = 0
   ?*food* = 0.0
   ?*water* = 0.0
   ?*clothing* = 0
   ?*bullets* = 0
   ?*wagon-wheels* = 0
   ?*wagon-axles* = 0
   ?*wagon-tongues* = 0
   ?*wheel-ok* = TRUE
   ?*axle-ok* = TRUE
   ?*tongue-ok* = TRUE
   ?*location-index* = 1
   ?*days-to-next* = 8.0
   ?*extra-water-today* = 0.0
   ?*traveled-today* = FALSE)

(deftemplate boot
   (slot ready (default TRUE)))
