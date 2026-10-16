[20][20]int matr;
[500]int Iqueue;
[500]int Jqueue;
int g, l, h;
int iKub, jKub;
int iStart, jStart;
int max;
int time;

func push(int i, j) {
    l = l + 1; h = h +1; 
    Iqueue[h] = i;
    Jqueue[h] = j; 
};

func pop(var int i, j) { 
    l = l -1;

    i = Iqueue[g];
    j = Jqueue[g];

    g = g + 1;
};

func BFS(int i, j) {
    int numb;
    push(i, j);
    matr[i][j] = 1;

    while l > 0 do {
        pop(i, j);

        numb = matr[i][j] + 1;

        if (matr[i-1][j] == 0) and (i-1 > 0) then {
            push(i-1, j);
            matr[i-1][j] = numb; 
        };
        if (matr[i+1][j] == 0) and (i+1 <= max) then {
            push(i+1, j);
            matr[i+1][j] = numb;
        };
        if (matr[i][j-1] == 0) and (j-1 > 0) then {
            push(i, j-1);
            matr[i][j-1] = numb;
        };
        if (matr[i][j+1] == 0) and (j + 1 <= max) then {
            push(i, j+1);
            matr[i][j+1] = numb;
        };
    }
};

func DrawAll {
    int i, j;
    int col;

    BeginDrawing;
        ClearBackground(15);

        for i = 1 to 10 do {
            for j = 1 to 10 do {
                if matr[i][j] == 255 then {
                    DrawRectangle(j*60-60, i*60-60, 60, 60, 12);
                } 
                else {
                    if matr[i][j] == 10000 then {
                        DrawRectangle(j*60-60, i*60-60, 60, 60, 11);
                        DrawText("start", j*60-50, i*60-40, 15, 0);
                    }
                    else {
                        if matr[i][j] != 0 then {
                            DrawText(str(matr[i][j]), j*60-40, i*60-40, 30, 0);
                        };
                    };
                }
            }
        };

        DrawRectangle(jKub*60, iKub*60, 60, 60, 11);
        if matr[iKub+1][jKub+1] == 255 then {col = 12}
        else {
            if matr[iKub+1][jKub+1] == 0 then {col = 15}
            else {
                if matr[iKub+1][jKub+1] == 10000 then {col = 11}
                else {
                    col = 15;
                };
            } 
        };
        DrawRectangle(jKub*60+5, iKub*60+5, 50, 50, col);
        if matr[iKub+1][jKub+1] == 10000 then {
            DrawText("start", jKub*60+10, iKub*60+20, 15, 0)
        }
        else {
            if (matr[iKub+1][jKub+1] != 255) and (matr[iKub+1][jKub+1] != 0) then {
                col = 15;
                DrawText(str(matr[iKub+1][jKub+1]), jKub*60+20, iKub*60+20, 30, 0);
            }
        };

        

    EndDrawing;
}

func ObrPlayer(var int i, j) {
    int x, y;
    x = GetMouseX; y = GetMouseY;

    if (x > 0) and (x < max*60) and (y > 0) and (y < max*60) then {
        i = y //60;
        j = x // 60;
    };

    if IsKeyPressed(87) then {
        i = i - 1
    }; # W
    if IsKeyPressed(83) then {i = i + 1}; # S
    if IsKeyPressed(65) then {j = j - 1}; # A
    if IsKeyPressed(68) then {j = j + 1}; # D

    # пробел
    if IsKeyPressed(32) then {
        
        if matr[i+1][j+1] == 0 then {
            matr[i+1][j+1] = 255;
        }
        else {
            matr[i+1][j+1] = 0;
        }
    };

    # ЛКМ
    if MouseButtonDown(0) then {
        matr[y // 60 + 1][x // 60 + 1] = 255;
    };

    # ПКМ
    if MouseButtonDown(1) then {
        matr[y // 60 + 1][x // 60 + 1] = 0;
    }
};

func ObrKeyBoard {
    int i,j;

    if IsKeyPressed(257) then {BFS(iStart, jStart)};
        if IsKeyPressed(340) then {
            for i = 1 to 10 do {
                for j = 1 to 10 do {
                    if matr[i][j] != 255 then {matr[i][j] = 0};
                }
            }
        };
        if IsKeyPressed(344) then {
            for i = 1 to 10 do {
                for j = 1 to 10 do {
                    matr[i][j] = 0;
                }
            }
        };
        if IsKeyPressed(69) then {
            matr[iKub+1][jKub+1] = 10000;
            if matr[iStart][jStart] == 10000 then {matr[iStart][jStart] = 0};
            iStart = iKub+1; jStart = jKub+1;
        }
};
 

func main {
    g =1; l = 0; h = 0;

    int x, y; char c;
    iKub = 0; jKub = 0;
    iStart = 2; jStart = 2;

    max = 10;

    
    InitGraph(600, 600, "Волновой алгоритм");

    while WindowNotClose do {
        ObrPlayer(iKub, jKub);

        DrawAll;

        ObrKeyBoard;
    }
}