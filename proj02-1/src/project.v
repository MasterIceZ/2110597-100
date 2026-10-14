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
  localparam ROW = 448 >> 4;
  localparam COL = 640 >> 3;
  localparam CELLS = ROW * COL;
  localparam AW = $clog2(CELLS);

  // VGA signals
  wire hsync_raw;
  wire vsync_raw;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  // TinyVGA PMOD
  // assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  // assign uio_out = 0;
  // assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  wire frame_tick = (pix_x == 0) && (pix_y == 10'd480);

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync_raw),
    .vsync(vsync_raw),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );
  
  wire inp_b, inp_y, inp_select, inp_start, inp_up, inp_down, inp_left, inp_right, inp_a, inp_x, inp_l, inp_r, inp_present;
  gamepad_pmod_single gamepad (
    .rst_n(rst_n),
    .clk(clk),
    .pmod_data(ui_in[6]),
    .pmod_clk(ui_in[5]),
    .pmod_latch(ui_in[4]),

    .b(inp_b),
    .y(inp_y),
    .select(inp_select),
    .start(inp_start),
    .up(inp_up),
    .down(inp_down),
    .left(inp_left),
    .right(inp_right),
    .a(inp_a),
    .x(inp_x),
    .l(inp_l),
    .r(inp_r),
    .is_present(inp_present)
  );

  wire [5:0] button_pressed;
  button_sanitizer #(
    .WIDTH(6)
  ) taps (
    .clk(clk),
    .rst_n(rst_n),
    .tick(frame_tick),
    .btn({inp_l, inp_r, inp_y, inp_x, inp_select, inp_start}),

    .pressed(button_pressed)
  );

  wire [9:0] cur_x;
  wire [9:0] cur_y;
  cursor_controller #(
    .ROW(ROW),
    .COL(COL)
  ) cursor (
    .clk(clk),
    .rst_n(rst_n),
    .tick(frame_tick),
    .up(inp_up),
    .down(inp_down),
    .left(inp_left),
    .right(inp_right),

    .cur_x(cur_x),
    .cur_y(cur_y)
  );

  wire we;
  wire [AW-1:0] wr_addr, rd_addr;
  wire [4:0] wr_data, rd_data;

  canvas_writer #(
    .COL(COL),
    .CELLS(CELLS),
    .AW(AW)
  ) writer (
    .clk(clk),
    .rst_n(rst_n),
    .clear_req(frame_tick & button_pressed[1]),
    .paint(inp_a),
    .erase(inp_b),
    .cursor_x(cur_x),
    .cursor_y(cur_y),
    .selected_color(selected_color),
    .selected_brush(selected_brush),
    
    .we(we),
    .wr_addr(wr_addr),
    .wr_data(wr_data)
  );

  simple_dualport_ram #(
    .AW(AW),
    .DEPTH(CELLS),
    .DW(5)
  ) canvas (
    .clk(clk),
    .we(we),
    .wr_addr(wr_addr),
    .wr_data(wr_data),
    .rd_addr(rd_addr),

    .rd_data(rd_data)
  );

  wire [2:0] selected_color;
  wire [1:0] selected_brush;
  wire grid_on;

  tool_select tools (
    .clk(clk),
    .rst_n(rst_n),
    .tick(frame_tick),
    .color_prev(button_pressed[5]),
    .color_next(button_pressed[4]),
    .brush_prev(button_pressed[3]),
    .brush_next(button_pressed[2]),
    .grid_toggle(button_pressed[0]),
    
    .selected_color(selected_color),
    .selected_brush(selected_brush),
    .grid_on(grid_on)
  );

  wire [9:0] pix_x_1, pix_y_1, pix_x_2, pix_y_2;
  wire de2, hsync, vsync;
  frame_delay dly(
    .clk(clk),
    .pix_x(pix_x),
    .pix_y(pix_y),

    .video_active(video_active),
    .hsync_in(hsync_raw),
    .vsync_in(vsync_raw),

    .pix_x_1(pix_x_1),
    .pix_y_1(pix_y_1),

    .pix_x_2(pix_x_2),
    .pix_y_2(pix_y_2),

    .de2(de2),
    .hsync(hsync),
    .vsync(vsync)
  );

  wire[5:0] canvas_rgb;

  canvas_renderer #(
    .COL(COL),
    .ROW(ROW),
    .AW(AW)
  ) canvas_view (
    .clk(clk),
    .rst_n(rst_n),
    .frame_tick(frame_tick),

    .pix_x(pix_x),
    .pix_y(pix_y),
    .rd_addr(rd_addr),

    .pix_x_1(pix_x_1),
    .pix_y_1(pix_y_1),
    .cell_data(rd_data),

    .pix_x_2(pix_x_2),
    .pix_y_2(pix_y_2),

    .cursor_x(cur_x),
    .cursor_y(cur_y),
    .selected_color(selected_color),
    .selected_brush(selected_brush),
    .grid_on(grid_on),

    .rgb(canvas_rgb)
  );

  wire[5:0] toolbar_rgb;
  toolbar_renderer toolbar_view (
    .clk(clk),
  
    .pix_x_1(pix_x_1),
    .pix_y_1(pix_y_1),

    .pix_x_2(pix_x_2),
    .pix_y_2(pix_y_2),

    .selected_color(selected_color),
    .selected_brush(selected_brush),

    .rgb(toolbar_rgb)
  );

  wire [5:0] rgb = !de2 ? 0 :
                  (pix_y_2 < 448) ? canvas_rgb : toolbar_rgb;

  assign uo_out = {hsync, rgb[0], rgb[2], rgb[4], vsync, rgb[1], rgb[3], rgb[5]};
  assign uio_out = 0;
  assign uio_oe = 0;

  // Suppress unused signals warning
  // wire _unused_ok_ = &{};

endmodule 