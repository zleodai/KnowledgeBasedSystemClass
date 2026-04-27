from pathlib import Path
import sys
import textwrap

try:
    import clips
except ImportError as exc:
    print("Missing dependency: clipspy. Install it with: python -m pip install clipspy")
    raise SystemExit(1) from exc

try:
    import pygame
except ImportError as exc:
    print("Missing dependency: pygame. Install it with: python -m pip install pygame")
    raise SystemExit(1) from exc


ROOT = Path(__file__).resolve().parent
CLP_FILES = ("definitions.clp", "kernel.clp", "data.clp", "game.clp")

SCREEN_W = 1280
SCREEN_H = 1010
FPS = 60

BLACK = (9, 13, 10)
PANEL = (17, 27, 20)
PANEL_DARK = (12, 20, 15)
GREEN = (99, 221, 111)
GREEN_DIM = (50, 128, 65)
AMBER = (235, 185, 88)
RED = (239, 88, 76)
BLUE = (88, 176, 220)
WHITE = (224, 236, 217)
GRAY = (94, 111, 94)

ITEMS = [
    ("oxen", "Yoke of Oxen", "$40.00", 1, "1 yoke"),
    ("food", "100 lbs of Food", "$20.00", 100, "100 lbs"),
    ("water", "50 gallons of Water", "$10.00", 50, "50 gallons"),
    ("clothing", "Set of Clothing", "$10.00", 1, "1 set"),
    ("bullets", "Box of Bullets", "$2.00", 1, "1 box"),
    ("wheel", "Wagon Wheel", "$10.00", 1, "1 wheel"),
    ("axle", "Wagon Axle", "$10.00", 1, "1 axle"),
    ("tongue", "Wagon Tongue", "$10.00", 1, "1 tongue"),
]

LOCATION_TYPES = {
    "fort": (AMBER, "F"),
    "river": (BLUE, "R"),
    "landmark": (GREEN, "L"),
    "dangerous": (RED, "!"),
    "end": (WHITE, "*"),
    "trail": (GREEN_DIM, "."),
}


class ClipsRouter(clips.Router):
    def __init__(self):
        super().__init__("pygame-router", 100)
        self.stdin = []
        self.output = []

    def push_line(self, line):
        for char in f"{line}\n":
            self.stdin.append(ord(char))

    def query(self, name):
        return name in ("stdin", "stdout", "werror", "wwarning", "wtrace", "wdialog")

    def write(self, name, message):
        self.output.append(message)

    def read(self, name):
        if not self.stdin:
            # The terminal game asks only one mid-action prompt during GUI play:
            # whether to spend ammunition during a wild animal attack. The GUI
            # auto-answers yes so CLIPS never blocks inside a Pygame frame.
            self.push_line("yes")
        return self.stdin.pop(0)

    def unread(self, name, char):
        if char != -1:
            self.stdin.insert(0, char)
        return char

    def pop_output(self):
        text = "".join(self.output)
        self.output = []
        return text


class ClipsGame:
    def __init__(self):
        self.env = clips.Environment()
        self.router = ClipsRouter()
        self.env.add_router(self.router)
        for name in CLP_FILES:
            self.env.load(str(ROOT / name))
        self.env.eval("(reset)")
        self.router.pop_output()
        self.log = []
        self.last_trade = None

    def eval(self, expression):
        value = self.env.eval(expression)
        self.capture_output()
        return value

    def capture_output(self):
        text = self.router.pop_output()
        if not text:
            return
        for raw in text.splitlines():
            line = raw.rstrip()
            if line:
                self.log.append(line)
        self.log = self.log[-220:]

    def log_line(self, line):
        self.log.append(line)
        self.log = self.log[-220:]

    def global_value(self, name):
        return self.env.eval(name)

    def global_int(self, name):
        return int(float(self.global_value(name)))

    def global_float(self, name):
        return float(self.global_value(name))

    def clip_bool(self, value):
        return str(value) == "TRUE"

    def game_over(self):
        return self.clip_bool(self.global_value("?*game-over*"))

    def won(self):
        return self.clip_bool(self.global_value("?*won*"))

    def set_profession(self, profession):
        self.eval(f"(set-starting-money {profession})")
        self.log_line(f"Profession selected: {profession}. Starting money: ${self.global_float('?*money*'):.2f}.")

    def add_companions(self, names):
        used = set()
        for raw_name in names:
            name = raw_name.strip()
            if not name:
                name = str(self.env.eval("(random-companion-name)"))
                while name in used:
                    name = str(self.env.eval("(random-companion-name)"))
            used.add(name)
            escaped = name.replace("\\", "\\\\").replace('"', '\\"')
            self.eval(f'(add-companion "{escaped}")')
        self.log_line("Companions: " + ", ".join(used))

    def price(self, item):
        return float(self.env.eval(f"(item-price {item})"))

    def item_plural(self, item):
        return str(self.env.eval(f"(item-name-plural {item})"))

    def item_name(self, item):
        return str(self.env.eval(f"(item-name {item})"))

    def buy(self, item, amount):
        cost = self.price(item) * amount
        money = self.global_float("?*money*")
        if cost > money:
            self.log_line(f"Cannot buy {amount} {self.item_plural(item)}. Need ${cost:.2f}, have ${money:.2f}.")
            return False
        self.eval(f"(bind ?*money* {money - cost})")
        self.eval(f"(add-inventory {item} {amount})")
        self.log_line(f"Bought {amount} {self.item_plural(item)} for ${cost:.2f}.")
        return True

    def state(self):
        index = self.global_int("?*location-index*")
        next_index = min(index + 1, 18)
        companions = tuple(self.env.eval("?*companion-names*"))
        companion_health = tuple(self.env.eval("?*companion-health*"))
        companion_fatigue = tuple(self.env.eval("?*companion-fatigue*"))
        return {
            "day": self.global_int("?*day*"),
            "money": self.global_float("?*money*"),
            "location_index": index,
            "location": str(self.env.eval(f"(location-name {index})")),
            "location_type": str(self.env.eval(f"(location-type {index})")),
            "next_location": str(self.env.eval(f"(location-name {next_index})")),
            "days_to_next": self.global_float("?*days-to-next*"),
            "food": self.global_float("?*food*"),
            "water": self.global_float("?*water*"),
            "oxen": self.global_int("?*oxen*"),
            "clothing": self.global_int("?*clothing*"),
            "bullets": self.global_int("?*bullets*"),
            "wheel_spares": self.global_int("?*wagon-wheels*"),
            "axle_spares": self.global_int("?*wagon-axles*"),
            "tongue_spares": self.global_int("?*wagon-tongues*"),
            "wheel_ok": self.clip_bool(self.global_value("?*wheel-ok*")),
            "axle_ok": self.clip_bool(self.global_value("?*axle-ok*")),
            "tongue_ok": self.clip_bool(self.global_value("?*tongue-ok*")),
            "leader_health": self.global_int("?*leader-health*"),
            "leader_fatigue": self.global_int("?*leader-fatigue*"),
            "companions": companions,
            "companion_health": companion_health,
            "companion_fatigue": companion_fatigue,
        }

    def health_name(self, value):
        return str(self.env.eval(f"(health-name {int(value)})"))

    def fatigue_name(self, value):
        return str(self.env.eval(f"(fatigue-name {int(value)})"))

    def location_name(self, index):
        return str(self.env.eval(f"(location-name {index})"))

    def location_type(self, index):
        return str(self.env.eval(f"(location-type {index})"))

    def travel(self):
        self.eval('(action-banner "TRAVEL")')
        self.eval("(travel-day)")
        if not self.game_over():
            self.eval("(end-day)")

    def rest(self):
        self.eval('(action-banner "REST")')
        self.eval("(improve-party-rest)")
        if not self.game_over():
            self.eval("(end-day)")

    def repair(self, part):
        self.eval('(action-banner "REPAIR WAGON")')
        self.router.push_line(part)
        result = self.eval("(repair-day)")
        if str(result) == "TRUE" and not self.game_over():
            self.eval("(end-day)")
            return True
        return False

    def make_trade(self):
        fort = "TRUE" if self.location_type(self.global_int("?*location-index*")) == "fort" else "FALSE"
        trade = self.eval(f"(make-trade {fort})")
        self.last_trade = {
            "offer_item": str(trade[0]),
            "offer_qty": float(trade[1]),
            "request_item": str(trade[2]),
            "request_qty": float(trade[3]),
            "gain": float(trade[4]),
        }
        return self.last_trade

    def trade_text(self, trade):
        offer_qty = pretty_num(trade["offer_qty"])
        request_qty = pretty_num(trade["request_qty"])
        return (
            f"Local offers {offer_qty} {self.item_plural(trade['offer_item'])} "
            f"for {request_qty} {self.item_plural(trade['request_item'])}."
        )

    def accept_trade(self):
        if not self.last_trade:
            return False
        trade = self.last_trade
        expr = (
            "(accept-trade "
            f"(create$ {trade['offer_item']} {trade['offer_qty']} "
            f"{trade['request_item']} {trade['request_qty']} {trade['gain']}))"
        )
        result = self.eval(expr)
        return str(result) == "TRUE"

    def finish_trade_day(self):
        self.log_line("Trading takes the rest of the day.")
        if not self.game_over():
            self.eval("(end-day)")


class Button:
    def __init__(self, rect, label, action, enabled=True, small=False):
        self.rect = pygame.Rect(rect)
        self.label = label
        self.action = action
        self.enabled = enabled
        self.small = small

    def draw(self, surface, fonts, mouse_pos):
        hover = self.rect.collidepoint(mouse_pos) and self.enabled
        fill = (22, 54, 31) if hover else PANEL_DARK
        border = GREEN if self.enabled else GRAY
        text_color = WHITE if self.enabled else GRAY
        pygame.draw.rect(surface, fill, self.rect, border_radius=3)
        pygame.draw.rect(surface, border, self.rect, 2, border_radius=3)
        font = fonts["small"] if self.small else fonts["button"]
        draw_centered(surface, font, self.label, self.rect, text_color)

    def handle(self, pos):
        if self.enabled and self.rect.collidepoint(pos):
            self.action()
            return True
        return False


class TextBox:
    def __init__(self, rect, text=""):
        self.rect = pygame.Rect(rect)
        self.text = text
        self.active = False

    def draw(self, surface, fonts):
        border = AMBER if self.active else GREEN_DIM
        pygame.draw.rect(surface, PANEL_DARK, self.rect, border_radius=3)
        pygame.draw.rect(surface, border, self.rect, 2, border_radius=3)
        shown = self.text or "Leave blank for random name"
        color = WHITE if self.text else GRAY
        surface.blit(fonts["body"].render(shown, True, color), (self.rect.x + 10, self.rect.y + 10))

    def click(self, pos):
        self.active = self.rect.collidepoint(pos)
        return self.active

    def key(self, event):
        if not self.active:
            return
        if event.key == pygame.K_BACKSPACE:
            self.text = self.text[:-1]
        elif event.key in (pygame.K_RETURN, pygame.K_TAB):
            self.active = False
        elif event.unicode and len(self.text) < 22 and event.unicode.isprintable():
            self.text += event.unicode


class OregonTrailGUI:
    def __init__(self):
        pygame.init()
        pygame.display.set_caption("CLIPS Oregon Trail")
        self.screen = pygame.display.set_mode((SCREEN_W, SCREEN_H))
        self.clock = pygame.time.Clock()
        self.fonts = {
            "title": pygame.font.SysFont("consolas", 34, bold=True),
            "header": pygame.font.SysFont("consolas", 22, bold=True),
            "body": pygame.font.SysFont("consolas", 17),
            "small": pygame.font.SysFont("consolas", 14),
            "button": pygame.font.SysFont("consolas", 16, bold=True),
        }
        self.game = ClipsGame()
        self.stage = "profession"
        self.buttons = []
        self.text_boxes = [TextBox((430, 190 + index * 58, 420, 40)) for index in range(5)]
        self.trade_active = False
        self.current_trade = None
        self.shop_message = "Shopkeeper recommends 200 lbs food and 100 gallons water per person."
        self.log_scroll = 0
        self.log_lines = []
        self.log_visible_count = 0
        self.running = True

    def run(self):
        while self.running:
            mouse_pos = pygame.mouse.get_pos()
            self.handle_events()
            self.draw(mouse_pos)
            pygame.display.flip()
            self.clock.tick(FPS)
        pygame.quit()

    def handle_events(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False
            elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                for box in self.text_boxes:
                    box.click(event.pos)
                for button in list(self.buttons):
                    if button.handle(event.pos):
                        break
            elif event.type == pygame.MOUSEWHEEL and self.stage in ("trail", "trade", "gameover"):
                self.scroll_log(-event.y * 3)
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    if self.stage == "trade":
                        self.finish_trade()
                    else:
                        self.running = False
                for box in self.text_boxes:
                    box.key(event)

    def draw(self, mouse_pos):
        self.screen.fill(BLACK)
        draw_scanlines(self.screen)
        self.buttons = []

        if self.stage == "profession":
            self.draw_profession(mouse_pos)
        elif self.stage == "companions":
            self.draw_companions(mouse_pos)
        elif self.stage == "shop":
            self.draw_shop(mouse_pos)
        elif self.stage == "trail":
            self.draw_trail(mouse_pos)
        elif self.stage == "trade":
            self.draw_trail(mouse_pos, dim=True)
            self.buttons = []
            self.draw_trade_overlay(mouse_pos)
        elif self.stage == "gameover":
            self.draw_trail(mouse_pos, dim=True)
            self.buttons = []
            self.draw_gameover(mouse_pos)

    def add_button(self, rect, label, action, enabled=True, small=False):
        button = Button(rect, label, action, enabled, small)
        self.buttons.append(button)
        return button

    def max_log_scroll(self):
        return max(0, len(self.log_lines) - self.log_visible_count)

    def clamp_log_scroll(self):
        self.log_scroll = max(0, min(self.log_scroll, self.max_log_scroll()))

    def scroll_log(self, amount):
        self.log_scroll += amount
        self.clamp_log_scroll()

    def draw_buttons(self, mouse_pos):
        for button in self.buttons:
            button.draw(self.screen, self.fonts, mouse_pos)

    def draw_profession(self, mouse_pos):
        panel = centered_rect(920, 560)
        draw_panel(self.screen, panel, "THE OREGON TRAIL", self.fonts)
        lines = [
            "Welcome to The Oregon Trail",
            "",
            "Choose a profession.",
        ]
        y = panel.y + 210
        for line in lines:
            draw_text(self.screen, self.fonts["body"], line, panel.x + 190, y, GREEN)
            y += 28

        button_y = panel.y + 365
        self.add_button((panel.x + 150, button_y, 190, 52), "Banker", lambda: self.choose_profession("banker"))
        self.add_button((panel.x + 365, button_y, 210, 52), "Carpenter", lambda: self.choose_profession("carpenter"))
        self.add_button((panel.x + 600, button_y, 170, 52), "Farmer", lambda: self.choose_profession("farmer"))
        self.draw_buttons(mouse_pos)

    def choose_profession(self, profession):
        self.game.set_profession(profession)
        self.stage = "companions"

    def draw_companions(self, mouse_pos):
        panel = centered_rect(740, 590)
        draw_panel(self.screen, panel, "Party", self.fonts)

        for index, box in enumerate(self.text_boxes, start=1):
            box.rect.topleft = (panel.x + 160, panel.y + 105 + (index - 1) * 58)
            draw_text(self.screen, self.fonts["body"], f"Companion {index}", panel.x + 30, box.rect.y + 10, WHITE)
            box.draw(self.screen, self.fonts)
        button_y = panel.y + 425
        self.add_button((panel.x + 160, button_y, 190, 50), "Randomize All", self.randomize_names)
        self.add_button((panel.x + 390, button_y, 190, 50), "Continue", self.finish_companions)
        self.draw_buttons(mouse_pos)

    def randomize_names(self):
        used = set()
        for box in self.text_boxes:
            name = str(self.game.env.eval("(random-companion-name)"))
            while name in used:
                name = str(self.game.env.eval("(random-companion-name)"))
            box.text = name
            used.add(name)

    def finish_companions(self):
        self.game.add_companions([box.text for box in self.text_boxes])
        self.stage = "shop"

    def draw_shop(self, mouse_pos):
        state = self.game.state()
        panel = centered_rect(1190, 665)
        draw_panel(self.screen, panel, "MATT'S GENERAL STORE", self.fonts)
        draw_text(self.screen, self.fonts["header"], f"Money: ${state['money']:.2f}", panel.x + 40, panel.y + 75, AMBER)
        draw_text(self.screen, self.fonts["body"], self.shop_message, panel.x + 40, panel.y + 115, GREEN)

        y = panel.y + 160
        for item, label, priceLabel, step, stepLabel in ITEMS:
            price = self.game.price(item)
            count = inventory_count(state, item)
            row = pygame.Rect(panel.x + 40, y, 1110, 48)
            pygame.draw.rect(self.screen, PANEL_DARK if y % 2 else PANEL, row)
            pygame.draw.rect(self.screen, GREEN_DIM, row, 1)
            draw_text(self.screen, self.fonts["body"], label, panel.x + 60, y + 14, WHITE)
            draw_text(self.screen, self.fonts["small"], priceLabel, panel.x + 290, y + 16, GREEN)
            draw_text(self.screen, self.fonts["small"], f"Owned: {pretty_num(count)}", panel.x + 440, y + 16, AMBER)
            self.add_button((panel.x + 975, y + 7, 155, 34), f"Buy {stepLabel}", lambda i=item, s=step: self.buy_shop(i, s), small=True)
            y += 52

        self.add_button((panel.right - 245, panel.bottom - 68, 185, 46), "Begin Trail", self.begin_trail)
        self.draw_buttons(mouse_pos)

    def buy_shop(self, item, step):
        if self.game.buy(item, step):
            self.shop_message = f"Bought {step} {self.game.item_plural(item)}."
        else:
            self.shop_message = "Not enough money for that purchase."

    def begin_trail(self):
        self.game.log_line("Your wagon rolls west from Independence.")
        self.stage = "trail"

    def draw_trail(self, mouse_pos, dim=False):
        state = self.game.state()
        draw_panel(self.screen, (25, 25, 780, 235), f"DAY {state['day']} - {state['location']}", self.fonts)
        draw_map(self.screen, self.fonts, self.game, state, pygame.Rect(50, 86, 730, 130))
        if state["location_index"] < 18:
            draw_text(self.screen, self.fonts["body"], f"Next: {state['next_location']}", 55, 226, WHITE)
            draw_text(self.screen, self.fonts["body"], f"{state['days_to_next']:.1f} travel-days away", 405, 226, AMBER)

        draw_panel(self.screen, (825, 25, 430, 640), "STATUS", self.fonts)
        self.draw_status(state)

        draw_panel(self.screen, (25, 280, 780, 680), "TRAIL LOG", self.fonts)
        self.draw_log(pygame.Rect(50, 330, 730, 530), mouse_pos)

        draw_panel(self.screen, (825, 685, 430, 275), "ACTIONS", self.fonts)
        self.draw_action_buttons(mouse_pos)

        if dim:
            overlay = pygame.Surface((SCREEN_W, SCREEN_H), pygame.SRCALPHA)
            overlay.fill((0, 0, 0, 130))
            self.screen.blit(overlay, (0, 0))

        if self.game.game_over() and self.stage != "gameover":
            self.stage = "gameover"

    def draw_status(self, state):
        x = 850
        y = 78

        clothingInfo = ("Clothing", f"{state["clothing"]} sets of clothing") if state["clothing"] != 1 else ("Clothing", f"{state["clothing"]} set of clothing")
        bulletInfo = ("Bullets", f"{state["bullets"]} boxes of bullets") if state["bullets"] != 1 else ("Bullets", f"{state["bullets"]} box of bullets")
        oxenInfo = ("Oxen yokes", f"{state["oxen"]} yokes of oxen") if state["oxen"] != 1 else ("Oxen yokes", f"{state["oxen"]} yoke of oxen") 

        lines = [
            ("Food", f"{state['food']:.1f} lbs"),
            ("Water", f"{state['water']:.1f} gal"),
            clothingInfo,
            bulletInfo,
            oxenInfo,
            ("Spares", f"W{state['wheel_spares']} A{state['axle_spares']} T{state['tongue_spares']}"),
        ]
        for label, value in lines:
            draw_text(self.screen, self.fonts["small"], f"{label}:", x, y, GREEN)
            draw_text(self.screen, self.fonts["small"], str(value), x + 130, y, WHITE)
            y += 24

        y += 10
        draw_text(self.screen, self.fonts["body"], "Wagon", x, y, AMBER)
        y += 28
        for label, ok in (("Wheel", state["wheel_ok"]), ("Axle", state["axle_ok"]), ("Tongue", state["tongue_ok"])):
            color = GREEN if ok else RED
            draw_text(self.screen, self.fonts["small"], f"{label}: {'OK' if ok else 'BROKEN'}", x, y, color)
            y += 22

        y += 8
        draw_text(self.screen, self.fonts["body"], "Party", x, y, AMBER)
        y += 26
        leader = f"You: {self.game.health_name(state['leader_health'])}, {self.game.fatigue_name(state['leader_fatigue'])}"
        draw_text(self.screen, self.fonts["small"], leader, x, y, WHITE)
        y += 22
        for name, health, fatigue in zip(state["companions"], state["companion_health"], state["companion_fatigue"]):
            text = f"{name}: {self.game.health_name(health)}, {self.game.fatigue_name(fatigue)}"
            draw_text(self.screen, self.fonts["small"], text[:44], x, y, WHITE)
            y += 20

    def build_log_lines(self):
        wrapped = []
        for line in self.game.log[-160:]:
            if set(line) == {"="}:
                wrapped.append(line[:70])
            else:
                wrapped.extend(textwrap.wrap(line, width=76) or [""])
        return wrapped

    def draw_log(self, rect, mouse_pos):
        pygame.draw.rect(self.screen, (7, 11, 8), rect)
        pygame.draw.rect(self.screen, GREEN_DIM, rect, 1)
        self.log_lines = self.build_log_lines()
        self.log_visible_count = max(1, (rect.height - 20) // 19)
        self.clamp_log_scroll()
        start = max(0, len(self.log_lines) - self.log_visible_count - self.log_scroll)
        end = min(len(self.log_lines), start + self.log_visible_count)
        visible = self.log_lines[start:end]
        y = rect.y + 10
        for line in visible:
            color = RED if line.startswith("URGENT") or "BROKEN" in line else GREEN
            if line.startswith("EVENT") or line.startswith("LOCATION"):
                color = AMBER
            draw_text(self.screen, self.fonts["small"], line, rect.x + 10, y, color)
            y += 19

        can_scroll_up = self.log_scroll < self.max_log_scroll()
        can_scroll_down = self.log_scroll > 0
        self.add_button((50, 880, 110, 36), "Log Up", lambda: self.scroll_log(6), can_scroll_up, small=True)
        self.add_button((175, 880, 130, 36), "Log Down", lambda: self.scroll_log(-6), can_scroll_down, small=True)
        self.add_button((320, 880, 150, 36), "Latest", lambda: self.scroll_log(-self.log_scroll), can_scroll_down, small=True)
        self.draw_buttons(mouse_pos)

    def draw_action_buttons(self, mouse_pos):
        disabled = self.game.game_over()
        self.add_button((855, 745, 160, 46), "Travel", self.do_travel, not disabled)
        self.add_button((1035, 745, 160, 46), "Rest", self.do_rest, not disabled)
        self.add_button((855, 808, 160, 46), "Trade", self.start_trade, not disabled)
        self.add_button((1035, 808, 160, 46), "Repair Wheel", lambda: self.do_repair("wheel"), not disabled)
        self.add_button((855, 870, 160, 46), "Repair Axle", lambda: self.do_repair("axle"), not disabled)
        self.add_button((1035, 870, 160, 46), "Repair Tongue", lambda: self.do_repair("tongue"), not disabled)
        self.draw_buttons(mouse_pos)

    def do_travel(self):
        self.game.travel()
        if self.game.game_over():
            self.stage = "gameover"

    def do_rest(self):
        self.game.rest()
        if self.game.game_over():
            self.stage = "gameover"

    def do_repair(self, part):
        self.game.repair(part)
        if self.game.game_over():
            self.stage = "gameover"

    def start_trade(self):
        self.game.eval('(action-banner "TRADE")')
        if self.game.location_type(self.game.global_int("?*location-index*")) == "fort":
            self.game.log_line("You are trading at a fort. Offers should favor you by up to $10.")
        else:
            self.game.log_line("You trade with locals near the trail. Offers may be fair or unfair.")
        self.current_trade = self.game.make_trade()
        self.stage = "trade"

    def draw_trade_overlay(self, mouse_pos):
        panel = centered_rect(730, 430)
        draw_panel(self.screen, panel, "TRADE WITH LOCALS", self.fonts)
        if not self.current_trade:
            self.current_trade = self.game.make_trade()
        trade_text = self.game.trade_text(self.current_trade)
        draw_wrapped(self.screen, self.fonts["header"], trade_text, panel.x + 60, panel.y + 80, 620, WHITE)
        draw_text(self.screen, self.fonts["small"], "Accept, skip for another offer, or finish trading to end the day.", panel.x + 60, panel.y + 203, GRAY)
        button_y = panel.y + 305
        self.add_button((panel.x + 60, button_y, 155, 48), "Accept", self.accept_trade)
        self.add_button((panel.x + 285, button_y, 155, 48), "Skip", self.skip_trade)
        self.add_button((panel.x + 510, button_y, 155, 48), "Done", self.finish_trade)
        self.draw_buttons(mouse_pos)

    def accept_trade(self):
        self.game.accept_trade()
        self.current_trade = self.game.make_trade()

    def skip_trade(self):
        self.game.log_line("Trade skipped.")
        self.current_trade = self.game.make_trade()

    def finish_trade(self):
        self.game.finish_trade_day()
        self.current_trade = None
        self.stage = "gameover" if self.game.game_over() else "trail"

    def draw_gameover(self, mouse_pos):
        panel = centered_rect(600, 360)
        draw_panel(self.screen, panel, "GAME OVER", self.fonts)
        if self.game.won():
            message = "You reached the Willamette Valley alive. You win!"
            color = GREEN
        else:
            message = "Your journey has ended before reaching the Willamette Valley."
            color = RED
        draw_wrapped(self.screen, self.fonts["header"], message, panel.x + 60, panel.y + 80, 480, color)
        state = self.game.state()
        draw_text(self.screen, self.fonts["body"], f"Final day: {max(1, state['day'] - 1)}", panel.x + 125, panel.y + 165, WHITE)
        draw_text(self.screen, self.fonts["body"], f"Final location: {state['location']}", panel.x + 125, panel.y + 200, WHITE)
        self.add_button((panel.centerx - 105, panel.y + 275, 210, 48), "Quit", self.quit)
        self.draw_buttons(mouse_pos)

    def quit(self):
        self.running = False


def inventory_count(state, item):
    if item == "oxen":
        return state["oxen"]
    if item == "food":
        return state["food"]
    if item == "water":
        return state["water"]
    if item == "clothing":
        return state["clothing"]
    if item == "bullets":
        return state["bullets"]
    if item == "wheel":
        return state["wheel_spares"]
    if item == "axle":
        return state["axle_spares"]
    return state["tongue_spares"]


def pretty_num(value):
    if int(value) == value:
        return str(int(value))
    return f"{value:.1f}"


def centered_rect(width, height):
    return pygame.Rect((SCREEN_W - width) // 2, (SCREEN_H - height) // 2, width, height)


def draw_panel(surface, rect, title, fonts):
    rect = pygame.Rect(rect)
    pygame.draw.rect(surface, PANEL, rect, border_radius=5)
    pygame.draw.rect(surface, GREEN_DIM, rect, 2, border_radius=5)
    pygame.draw.line(surface, GREEN_DIM, (rect.x + 16, rect.y + 48), (rect.right - 16, rect.y + 48), 1)
    draw_text(surface, fonts["header"], title, rect.x + 18, rect.y + 16, GREEN)


def draw_text(surface, font, text, x, y, color):
    surface.blit(font.render(str(text), True, color), (x, y))


def draw_centered(surface, font, text, rect, color):
    rendered = font.render(str(text), True, color)
    target = rendered.get_rect(center=rect.center)
    surface.blit(rendered, target)


def draw_wrapped(surface, font, text, x, y, width, color):
    average = max(1, font.size("M")[0])
    chars = max(12, width // average)
    for line in textwrap.wrap(text, width=chars):
        draw_text(surface, font, line, x, y, color)
        y += font.get_height() + 5


def draw_scanlines(surface):
    for y in range(0, SCREEN_H, 4):
        pygame.draw.line(surface, (0, 0, 0), (0, y), (SCREEN_W, y), 1)

def draw_map(surface, fonts, game, state, rect):
    pygame.draw.rect(surface, (7, 11, 8), rect)
    pygame.draw.rect(surface, GREEN_DIM, rect, 1)
    count = 18
    left = rect.x + 28
    right = rect.right - 28
    y = rect.y + 55
    points = []
    for index in range(1, count + 1):
        x = left + (right - left) * (index - 1) / (count - 1)
        points.append((int(x), y + (12 if index % 2 == 0 else -10)))
    pygame.draw.lines(surface, GREEN_DIM, False, points, 2)

    for index, point in enumerate(points, start=1):
        loc_type = game.location_type(index)
        color, marker = LOCATION_TYPES.get(loc_type, LOCATION_TYPES["trail"])
        radius = 9 if index == state["location_index"] else 6
        pygame.draw.circle(surface, color, point, radius, 2)
        if index == state["location_index"]:
            pygame.draw.circle(surface, color, point, radius + 5, 1)
            draw_text(surface, fonts["small"], "YOU", point[0] - 12, point[1] - 34, AMBER)
        elif loc_type in ("fort", "river", "dangerous", "end"):
            draw_text(surface, fonts["small"], marker, point[0] - 4, point[1] - 27, color)


def main():
    OregonTrailGUI().run()


if __name__ == "__main__":
    main()
