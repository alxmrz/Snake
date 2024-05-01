struc SDL_Rect x,y,width,height
{
    .x dd x
    .y dd y
    .w dd width
    .h dd height
}

struc SDL_Color r,g,b,a
{
    .r db r
    .g db g
    .b db b
    .a db a
}

SDL_INIT_EVERYTHING = 62001
SDL_WINDOW_SHOWN = 4

SDL_QUIT = 0x0100
SDL_KEYDOWN = 0x0300

SDL_LEFT_ARROW_KEY = 1073741904
SDL_RIGHT_ARROW_KEY = 1073741903
SDL_UP_ARROW_KEY = 1073741906
SDL_DOWN_ARROW_KEY = 1073741905
SDLK_SPACE = 32