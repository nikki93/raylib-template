#pragma once
#include "all.cc"


int main() {
  // Window initialization
  Vector2 viewSize { 800, 450 };
  auto windowSize = viewSize;
#ifdef __EMSCRIPTEN__
  windowSize = {
    float(EM_ASM_INT({ return document.querySelector("#canvas").getBoundingClientRect().width; })),
    float(EM_ASM_INT({ return document.querySelector("#canvas").getBoundingClientRect().height; })),
  };
#endif
  InitWindow(int(windowSize.x), int(windowSize.y), "");
  SetTargetFPS(120);

  // Window initialization
  auto spriteTexture = LoadTexture("assets/avatar.png");
  Vector2 spritePosition { 200, 200 };

  // Main loop
  static auto frame = [&]() {
    // Pause on window unfocus on web
    {
#ifdef __EMSCRIPTEN__
      static auto prevWindowFocused = true;
      bool focused = EM_ASM_INT({ return document.hasFocus() ? 1 : 0; });
      if (focused != prevWindowFocused) {
        prevWindowFocused = focused;
        if (focused) {
          emscripten_set_main_loop_timing(EM_TIMING_RAF, 0);
          return;
        } else {
          emscripten_set_main_loop_timing(EM_TIMING_SETTIMEOUT, 100);
        }
      }
      if (!focused) {
        return;
      }
#endif
    }

    // Update
    {
      if (IsMouseButtonDown(0)) {
        auto mousePosition = GetMousePosition();
        mousePosition.x *= viewSize.x / windowSize.x;
        mousePosition.y *= viewSize.y / windowSize.y;
        spritePosition = mousePosition;
      }
    }

    // Draw
    BeginDrawing();
    {
      rlPushMatrix();
      rlScalef(windowSize.x / viewSize.x, windowSize.y / viewSize.y, 1);

      ClearBackground({ 0x00, 0x00, 0x00, 0xff });

      rlPushMatrix();
      rlTranslatef(spritePosition.x, spritePosition.y, 0);
      rlScalef(2, 2, 1);
      DrawTexture(spriteTexture, 0, 0, WHITE);
      rlPopMatrix();

      rlPopMatrix();
    }
    EndDrawing();

    // Flush console
    std::fflush(stdout);
  };
#ifdef __EMSCRIPTEN__
  emscripten_set_main_loop(
      []() {
        frame();
      },
      0, true);
#else
  while (!WindowShouldClose()) {
    frame();
  }
#endif

  CloseWindow();

  return 0;
}
