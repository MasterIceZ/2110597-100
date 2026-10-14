module cursor_controller #(
  parameter ROW,
  parameter COL
) (
  input wire clk,
  input wire rst_n,
  input wire tick,
  input wire up,
  input wire down,
  input wire left,
  input wire right,

  output reg [9:0] cur_x,
  output reg [9:0] cur_y
);
  
  wire have_move = up | down | left | right;

  always @(posedge clk) begin
    if (~rst_n) begin
      cur_x <= 0;
      cur_y <= 0;
    end else if (tick) begin
      if(have_move) begin
        if (left && cur_x != 0) begin
          cur_x <= cur_x - 1'b1;
        end else if (right && cur_x != COL - 1) begin
          cur_x <= cur_x + 1'b1;
        end
        if (up && cur_y != 0) begin
          cur_y <= cur_y - 1'b1;
        end else if(down && cur_y != ROW - 1) begin
          cur_y <= cur_y + 1'b1;
        end
      end
    end
  end

endmodule