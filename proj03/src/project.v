/*
 * Copyright (c) 2024 Tiny Tapeout LTD
 * SPDX-License-Identifier: Apache-2.0
 * Author: Uri Shaked


 - Modified by Pongsgon Vichitvejpaisal to
  load 320x240 6-bit color image
 */

`default_nettype none

parameter IMG_SIZE = 320;  // Size of the image in pixels
parameter MUL_FACTOR = 2;   // vga_res/img_size
parameter DISPLAY_WIDTH = 640;  // VGA display width
parameter DISPLAY_HEIGHT = 480;  // VGA display height

`define COLOR_WHITE 3'd7

module tt_um_vga_example (
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
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  // TinyVGA PMOD
  assign uo_out  = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in[7:1], uio_in};

  hvsync_generator vga_sync_gen (
      .clk(clk),
      .reset(~rst_n),
      .hsync(hsync),
      .vsync(vsync),
      .display_on(video_active),
      .hpos(pix_x),
      .vpos(pix_y)
  );

  wire inp_a;

  gamepad_pmod_single gamepad_controller (
    .rst_n(rst_n),
    .clk(clk),
    .pmod_data(ui_in[6]),
    .pmod_clk(ui_in[5]),
    .pmod_latch(ui_in[4]),

    .a(inp_a)
  );

  reg [5:0] img[76799:0];  // 320x240
  reg [5:0] img2[76799:0];  // 320x240
  wire [16:0] mem_index;
  reg [5:0] color;

  initial begin
    $readmemh("../data/bg1_dithering.mem", img);
    $readmemh("../data/dinosaur.mem", img2);
  end

  reg [3:0] a;
  reg [10:0] counter;

  wire [4:0] r,g,b;
  assign r = ((5'd4-a)*img[mem_index][5:4]+a*img2[mem_index][5:4])>>2;
  assign g = ((5'd4-a)*img[mem_index][3:2]+a*img2[mem_index][3:2])>>2;
  assign b = ((5'd4-a)*img[mem_index][1:0]+a*img2[mem_index][1:0])>>2;

  always @(posedge clk)begin
      color <= {r[1:0],g[1:0],b[1:0]};
  end

  reg state;
  reg prev_a;

  always @(posedge vsync) begin
    if (~rst_n) begin
      state <= 0;
      prev_a <= 0;
      a <= 0;
      counter <= 0;
    end
    else begin
      prev_a <= inp_a;
      if (inp_a && !prev_a) begin
        state <= ~state;
        counter <= 0;
      end
      else if (counter < 60) begin
        counter <= counter+1;
      end
      else if (state == 1 && a < 4) begin
        a <= a+1;
        counter <= 0;
      end
      else if (state == 0 && a > 0) begin
        a <= a-1;
        counter <= 0;
      end
    end
  end

  assign mem_index = (pix_y / MUL_FACTOR) * IMG_SIZE + pix_x / MUL_FACTOR;
  //assign color = img[mem_index]+img2[mem_index];
  assign R = (video_active)? color[5:4]:0;
  assign G = (video_active)? color[3:2]:0;
  assign B = (video_active)? color[1:0]:0;



endmodule
