/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_vga_example(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  reg [1:0] R;
  reg [1:0] G;
  reg [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );

  wire [9:0] new_enemy_x;
  wire [8:0] new_enemy_y;

  wire [9:0] _rx;
  randomizer #(
    .RANGE(600),
    .SEED(16'h1234),
    .TAPS(16'hB400)
  ) rx (
    .clk(clk),
    .reset(~rst_n),
    .enable(vsync),
    .rnd(_rx)
  );

  assign new_enemy_x = _rx + 5;

  randomizer #(
    .RANGE(200),
    .SEED(16'hABCD),
    .TAPS(16'hD901)
  ) ry (
    .clk(clk),
    .reset(~rst_n),
    .enable(vsync),
    .rnd(new_enemy_y)
  );

  reg [9:0] enemy_x [0:2];
  reg [9:0] enemy_y [0:2];
  reg [2:0] enemy_alive;

  wire [1:0] free_enemy_slot = ~enemy_alive[0] ? 0 :
                        ~enemy_alive[1] ? 1 : 2;
  wire has_free_enemy_slot = ~(&enemy_alive);

  wire [2:0] is_enemy;
  
  genvar i;
  generate
    for(i=0; i<3; i=i+1) begin
      enemy #(
        .ENEMY_SIZE(20)
      ) e (
        .enemy_x(enemy_x[i]),
        .enemy_y(enemy_y[i]),
        .enemy_alive(enemy_alive[i]),

        .pix_x(pix_x),
        .pix_y(pix_y),

        .is_enemy(is_enemy[i])
      );
    end
  endgenerate
  
  reg [9:0] player_x;
  reg [9:0] player_y;

  wire is_player;
  player player(
    .player_x(player_x),
    .player_y(player_y),

    .pix_x(pix_x),
    .pix_y(pix_y),

    .is_player(is_player)
  );

  reg [9:0] bullet_x;
  reg [9:0] bullet_y;
  reg valid_bullet;

  wire is_bullet;
  bullet b(
    .bullet_x(bullet_x),
    .bullet_y(bullet_y),

    .pix_x(pix_x),
    .pix_y(pix_y),

    .is_bullet(is_bullet)
  );

  wire [2:0] collide;
  generate
    for(i=0; i<3; i=i+1) begin
      enemy #(
        .ENEMY_SIZE(20)
      ) e (
        .enemy_x(enemy_x[i]),
        .enemy_y(enemy_y[i]),
        .enemy_alive(enemy_alive[i]),

        .pix_x(bullet_x),
        .pix_y(bullet_y),

        .is_enemy(collide[i])
      );
    end
  endgenerate

  always @(*) begin
    R = 2'b00;
    G = 2'b00;
    B = 2'b00;
    if (video_active) begin
      if (|is_enemy) begin 
        R = 2'b11;
        G = 2'b11;
        B = 2'b00;
      end else if (is_player) begin
        R = 2'b11;
        G = 2'b00;
        B = 2'b00;
      end else if (is_bullet) begin
        R = 2'b11;
        G = 2'b11;
        B = 2'b11;
      end
    end
  end

  always @(posedge vsync, negedge rst_n) begin
    if (~rst_n) begin
      player_x <= 400;
      player_y <= 450;
    end else begin 
      if (has_free_enemy_slot) begin
        enemy_x[free_enemy_slot] <= new_enemy_x;
        enemy_y[free_enemy_slot] <= {1'b0, new_enemy_y};
        enemy_alive[free_enemy_slot] <= 1'b1;
      end
      
      if (^ui_in[2:1]) begin
        if (ui_in[1] && player_x - 30 > 0) begin
          player_x <= player_x - 10;
        end else if(ui_in[2] && player_x + 30 < 640) begin
          player_x <= player_x + 10;
        end
      end
      
      if (~valid_bullet) begin
        valid_bullet <= 1;
        bullet_x <= player_x;
        bullet_y <= player_y;
      end else begin
        if (bullet_y - 10 > 0) begin
          bullet_y <= bullet_y - 10;
        end else begin
          valid_bullet <= 0;
        end
      end

      if (|collide) begin
        if (collide[0]) begin
          enemy_alive[0] <= 0;
        end else if (collide[1]) begin
          enemy_alive[1] <= 0;
        end else if (collide[2]) begin
          enemy_alive[2] <= 0;
        end
      end

    end
  end

  // Suppress unused signals warning
  wire _unused_ok_ = &{pix_x, pix_y};

endmodule
