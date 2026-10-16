int gameOver, bombActive, kx, ky, ox, oy, bx, by, weight, height, kdx, kdy, kills;

func DrawKrolic(int kx, ky) {
    DrawCircle(kx, ky, 30, 8);               
    DrawEllipse(kx - 15, ky - 30, 6, 15, 8); 
    DrawEllipse(kx + 15, ky - 30, 6, 15, 8);    
    DrawEllipse(kx + 13, ky - 13, 5, 8, 15);
    DrawEllipse(kx - 13, ky - 13, 5, 8, 15);
    DrawCircle(kx - 13, ky - 13, 3, 0);
    DrawCircle(kx + 13, ky - 13, 3, 0);
    DrawCircle(kx, ky, 4, 12); 
};

func DrawOhotnik(int ox, oy) { 
    DrawCircle(ox, oy, 15, 12);
    DrawCircle(ox, oy, 13, 11);
    DrawLine(ox - 20, oy, ox + 20, oy, 12);
    DrawLine(ox, oy - 20, ox, oy + 20, 12);
};

func DrawBomb(int bx, by) {
    DrawCircle(bx, by, 15, 0);
    DrawCircle(bx - 3, by - 3, 4, 7);
};

func ObrBomb(var int bombTimer) {
    int rasst;

    if bombActive == 0 then {
        bombTimer = bombTimer - 1;
        if bombTimer == 0 then {
            bx = kx;
            by = ky;
            bombActive = 1;
            bombTimer = 60;
        };
    } 
    else {
        bombTimer = bombTimer - 1;
        if bombTimer == 0 then {
            bombActive = 0;
            bombTimer = 120;
                    
            rasst = (bx - ox) * (bx - ox) + (by - oy) * (by - oy);
            if rasst < 22500 then {
                gameOver = 1;
            };
        };
    };
};

func ObrPlayer {
    int rasst;
    if IsKeyDown(87) then {oy = oy - 5}; # W
    if IsKeyDown(83) then {oy = oy + 5}; # S
    if IsKeyDown(65) then {ox = ox - 5}; # A
    if IsKeyDown(68) then {ox = ox + 5}; # D

    if IsKeyPressed(32) then { # пробел
        rasst = (kx - ox) * (kx - ox) + (ky - oy) * (ky - oy);
                
        if rasst <= 1600 then {
            kx = random(50, weight);
            ky = random(50, height);
            kills = kills + 1;
        };
    };
};

func ObrKrolic {
    if random(0, 20) == 0 then {
        kdx = random(0-4, 4);
        kdy = random(0-4, 4);
    };

    kx = kx + kdx;
    ky = ky + kdy;

    if kx < 50 then {kdx = 4};
    if kx > weight-50 then {kdx = 0-4};
    if ky < 50 then {kdy = 4};
    if ky > height-50 then {kdy = 0-4};
}

func main {
    int bombTimer;

    kx = 250; ky = 250;
    
    ox = 200; oy = 200;
    
    bx = 0; by = 0;
    kdx = 0;  kdy = 0;
    bombActive = 0;
    bombTimer = 120;
    
    gameOver = 0;
    weight = 960; height = 480;
    kills = 0;

    InitGraph(weight, height, "Охота на кролика");

    while WindowNotClose do {
        
        if gameOver == 0 then {
            ObrPlayer; 
            ObrKrolic;
            ObrBomb(bombTimer);
        };
        # Рисованеи
        BeginDrawing;
            if gameOver == 0 then {
                ClearBackground(11);
                
                if bombActive == 1 then {DrawBomb(bx, by)};
              
                DrawKrolic(kx, ky);
                DrawOhotnik(ox, oy);

                DrawText("Kills: ", 10, 10, 25, 15);
                DrawText(str(kills), 80, 10, 25, 15);
            } 
            else {DrawCircle(random(0, weight), random(0, height), 15, random(0, 15))};

        EndDrawing;
    }
}