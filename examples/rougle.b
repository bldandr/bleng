[20][20]int matr;
int maxRow, maxCol;
int iPlayer, jPlayer;
int iEnemy, jEnemy;
int hp, gold, level;
int gameover;
int enemyTick;
Texture2D brick, zombie, steve, goldim, portal, zele;

func InitGame {
    maxRow = 15;
    maxCol = 17;
    hp = 100;
    gold = 0;
    level = 1;
    gameover = 0;
    iPlayer = 2;
    jPlayer = 2;
    iEnemy = 12;
    jEnemy = 12;
};

func InitTexture {
    brick = LoadTexture("examples/images/brick.png");
    zombie = LoadTexture("examples/images/zombie.png");
    steve = LoadTexture("examples/images/steve.png");
    goldim = LoadTexture("examples/images/gold.png");
    portal = LoadTexture("examples/images/portal.png");
    zele = LoadTexture("examples/images/zele.png");
};

func GenerateMap {
    int i, j; 
    for i = 1 to maxRow do {
        for j = 1 to maxCol do {
            if (i == 1) or (i == maxRow) or (j == 1) or (j == maxCol) then {
                matr[i][j] = 1; 
            }
            else {
                matr[i][j] = 0; 
            }
        }
    };

    matr[5][5] = 1; matr[5][6] = 1; matr[5][7] = 1;
    matr[10][3] = 1; matr[10][4] = 1;
    matr[3][10] = 1; matr[4][10] = 1;
    
    i = random(1, maxRow); j = random(1, maxCol);
    while matr[i][j] != 0 do {i = random(2, maxRow-1); j = random(2, maxCol-1);};
    matr[i][j] = 3; # Лестница
    while matr[i][j] != 0 do {i = random(2, maxRow-1); j = random(2, maxCol-1);};
    matr[i][j] = 2;  # Золото
    while matr[i][j] != 0 do {i = random(2, maxRow-1); j = random(2, maxCol-1);};
    matr[i][j] = 2;  # Золото
    while matr[i][j] != 0 do {i = random(2, maxRow-1); j = random(2, maxCol-1);};
    matr[i][j] = 2; # Золото
    
    matr[3][2] = 4;  # Зелье здоровья (хилка)
    matr[9][8] = 4;  # Зелье здоровья
};

func DrawAll {
    int i, j;
    BeginDrawing;
        ClearBackground(0); # Черный фон

        for i = 1 to maxRow do {
            for j = 1 to maxCol do {
                if matr[i][j] == 1 then {
                    DrawTexture(brick, j*35-35, i*35-35); 
                };
                if matr[i][j] == 2 then {
                    DrawTexture(goldim, j*35-35, i*35-35);
                };
                if matr[i][j] == 3 then {
                    DrawTexture(portal, j*35-35, i*35-35);
                };
                if matr[i][j] == 4 then {
                    DrawTexture(zele, j*35-25, i*35-25); 
                };
            }
        };

        # Игрок
        DrawTexture(steve, jPlayer*35-35, iPlayer*35-35);
        
        # Враг
        DrawTexture(zombie, jEnemy*35-35, iEnemy*35-35);

        # Статы на экране
        DrawText("HP:", 20, 540, 20, 15);
        DrawText(str(hp), 65, 540, 20, 10);
        
        DrawText("Gold:", 130, 540, 20, 15);
        DrawText(str(gold), 195, 540, 20, 6);

        DrawText("Lvl:", 260, 540, 20, 15);
        DrawText(str(level), 305, 540, 20, 7);

        if gameover == 1 then {
            DrawText("GAME OVER", 180, 250, 40, 2);
        };
    EndDrawing;
};

func ObrPlayer {
    int nextI, nextJ;
    nextI = iPlayer;
    nextJ = jPlayer;

    if IsKeyPressed(87) then { nextI = nextI - 1; }; # W
    if IsKeyPressed(83) then { nextI = nextI + 1; }; # S
    if IsKeyPressed(65) then { nextJ = nextJ - 1; }; # A
    if IsKeyPressed(68) then { nextJ = nextJ + 1; }; # D

    if matr[nextI][nextJ] != 1 then {
        iPlayer = nextI;
        jPlayer = nextJ;

        # Подобрали золото
        if matr[iPlayer][jPlayer] == 2 then {
            gold = gold + 100;
            matr[iPlayer][jPlayer] = 0;
        };

        # Переход на следующий уровень по лестнице
        if matr[iPlayer][jPlayer] == 3 then {
            level = level + 1;
            GenerateMap;
            iPlayer = 2;
            jPlayer = 2;
        };
        # Подобрали зелье
        if matr[iPlayer][jPlayer] == 4 then {
            hp = hp + 30;
            if hp > 100 then { hp = 100; }; # кап ХП
            matr[iPlayer][jPlayer] = 0;
        };

        # Удар по пробелу (атака врага)
        if IsKeyPressed(32) then {
            # Если моб стоит на соседней клетке
            if ((iPlayer - iEnemy == 1) or (iPlayer - iEnemy == 0) or (iEnemy - iPlayer == 1)) and 
            ((jPlayer - jEnemy == 1) or (jPlayer - jEnemy == 0) or (jEnemy - jPlayer == 1)) then {
                # Отбрасываем или наносим урон врагу
                iEnemy = iEnemy + 2; # отлетел назад
            }
        };
    };
};

func UpdateEnemy {
    enemyTick = enemyTick + 1;
    if enemyTick > 12 then {
        enemyTick = 0;

        int bestI, bestJ, minDist;
        bestI = iEnemy;
        bestJ = jEnemy;
        minDist = 9999;

        int d;

        if (iEnemy-1 > 0) and (matr[iEnemy-1][jEnemy] != 1) then {
            d = (iEnemy-1 - iPlayer)*(iEnemy-1 - iPlayer) + (jEnemy - jPlayer)*(jEnemy - jPlayer);
            if d < minDist then { minDist = d; bestI = iEnemy - 1; bestJ = jEnemy; };
        };
        if (iEnemy+1 <= maxRow) and (matr[iEnemy+1][jEnemy] != 1) then {
            d = (iEnemy+1 - iPlayer)*(iEnemy+1 - iPlayer) + (jEnemy - jPlayer)*(jEnemy - jPlayer);
            if d < minDist then { minDist = d; bestI = iEnemy + 1; bestJ = jEnemy; };
        };
        if (jEnemy-1 > 0) and (matr[iEnemy][jEnemy-1] != 1) then {
            d = (iEnemy - iPlayer)*(iEnemy - iPlayer) + (jEnemy-1 - jEnemy)*(jEnemy-1 - jEnemy);
        };

        if iEnemy < iPlayer and matr[iEnemy+1][jEnemy] != 1 then { iEnemy = iEnemy + 1; }
        else {
            if iEnemy > iPlayer and matr[iEnemy-1][jEnemy] != 1 then { iEnemy = iEnemy - 1; }
            else {
                if jEnemy < jPlayer and matr[iEnemy][jEnemy+1] != 1 then { jEnemy = jEnemy + 1; }
                else {
                    if jEnemy > jPlayer and matr[iEnemy][jEnemy-1] != 1 then { jEnemy = jEnemy - 1; };
                };
            };
        };

        if (iEnemy == iPlayer) and (jEnemy == jPlayer) then {
            hp = hp - 20; 
            if hp <= 0 then {
                gameover = 1;
            };
        };
    };
};

func main {
    InitGame;
    GenerateMap;
    InitGraph(600, 600, "Рогалик");
    InitTexture;

    while WindowNotClose do {
        if gameover == 0 then {
            ObrPlayer;
            UpdateEnemy;
        };
        DrawAll;
    }
}