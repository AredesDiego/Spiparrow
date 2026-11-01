#include <raylib.h>
#include "../include/tablero.hpp"

const short int screenWidth = 800;
const short int screenHeight = 600;

const short int boardSize = 8; // Número de filas y columnas del tablero
const short int margin = 50;   // Espacio adicional en los cuatro lados

// Tamaño de cada celda cuadrada, calculando el espacio disponible tras los márgenes
const short int cellSize = (screenWidth - 2 * margin < screenHeight - 2 * margin ? 
                            (screenWidth - 2 * margin) : (screenHeight - 2 * margin)) / boardSize;

int main () 
{
    InitWindow(screenWidth, screenHeight, "AJEDREZ");
    /* SetWindowState(FLAG_FULLSCREEN_MODE); */
    SetTargetFPS(60);

    // Cálculo del offset para centrar el tablero con márgenes
    const short int offsetX = (screenWidth - (boardSize * cellSize)) / 2;
    const short int offsetY = (screenHeight - (boardSize * cellSize)) / 2;

    while (!WindowShouldClose())
    {
        BeginDrawing();
        ClearBackground(BLUE);

        dibujarTablero(boardSize, cellSize, offsetX, offsetY);
        
        EndDrawing();
    }

    CloseWindow();
    return 0;
}
