import pygame

class Buttons:
    def __init__(self, headless=False):
        self.headless = headless

        self.cycle = 0
        self.up = False
        self.down = False
        self.left = False
        self.right = False
        self.a = False
        self.b = False
        self.start = False
        self.select = False

    def tick(self) -> bool:
        lx = self.cycle % 114
        ly = (self.cycle / 114) % 154
        self.cycle += 1

        if not self.update_buttons():
            return False

        if lx == 20 and ly == 0:
            return self.handle_inputs()
        else:
            return True


    def update_buttons(self) -> bool:
        if self.headless:
            return True

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.locals.K_ESCAPE:
                    return False
                if event.key == pygame.locals.K_Z:
                    self.b = True
                if event.key == pygame.locals.K_X:
                    self.a = True
                if event.key == pygame.locals.K_RETURN:
                    self.start = True
                if event.key == pygame.locals.K_SPACE:
                    self.select = True
                if event.key == pygame.locals.K_UP:
                    self.up = True
                if event.key == pygame.locals.K_DOWN:
                    self.down = True
                if event.key == pygame.locals.K_LEFT:
                    self.left = True
                if event.key == pygame.locals.K_RIGHT:
                    self.right = True
            elif event.type == pygame.KEYUP:
                if event.key == pygame.locals.K_Z:
                    self.b = False
                if event.key == pygame.locals.K_X:
                    self.a = False
                if event.key == pygame.locals.K_RETURN:
                    self.start = False
                if event.key == pygame.locals.K_SPACE:
                    self.select = False
                if event.key == pygame.locals.K_UP:
                    self.up = False
                if event.key == pygame.locals.K_DOWN:
                    self.down = False
                if event.key == pygame.locals.K_LEFT:
                    self.left = False
                if event.key == pygame.locals.K_RIGHT:
                    self.right = False
        return True

    def handle_inputs(self) -> bool:
        # TODO: implement this
        return True