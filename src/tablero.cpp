#include "../include/tablero.hpp"
// Dibujar el tablero con márgenes en todos los lados
void dibujarTablero(int boardSize, int cellSize, int offsetX, int offsetY) 
{
    // Dibujar el tablero con márgenes en todos los lados
    for (short int c = 0; c < boardSize; c++) 
    {
        for (short int r = 0; r < boardSize; r++) 
        {
            // Alternar colores del tablero
            Color colorTablero = ((r + c) % 2 == 0) ? WHITE : BLACK; 

            // Dibujar cada celda con el offset para centrar y márgenes alrededor
            DrawRectangle(r * cellSize + offsetX, c * cellSize + offsetY, cellSize, cellSize, colorTablero);
        }
    }
}