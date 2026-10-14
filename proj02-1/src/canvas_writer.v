module canvas_writer #(
  parameter COL,
  parameter CELLS,
  parameter AW
) (
  input wire clk,
  input wire rst_n,
  input wire clear_req,
  input wire paint,
  input wire erase,

  input wire [9:0] cursor_x,
  input wire [9:0] cursor_y,
  
  input wire [2:0] selected_color,
  input wire [1:0] selected_brush,

  output wire we,
  output wire [AW-1:0] wr_addr,
  output wire [4:0] wr_data
);

  localparam LAST = CELLS - 1;

  reg clearing;    
  reg [AW-1:0] clear_addr;

  always @(posedge clk) begin
    if(~rst_n) begin
      clearing <= 1;
      clear_addr <= {AW{1'b0}};
    end else if(clear_req) begin
      clearing <= 1;
      clear_addr <= {AW{1'b0}};
    end else if (clearing) begin
      clear_addr <= clear_addr + 1;
      if(clear_addr == LAST[AW-1:0]) begin
        clearing <= 0;
      end
    end
  end

  wire [19:0] cur_lin = {10'd0, cursor_y} * {10'd0, COL[9:0]} + {10'd0, cursor_x};
  wire [AW-1:0] cur_addr = cur_lin[AW-1:0];

  assign we = clearing | paint | erase;
  assign wr_addr = clearing ? clear_addr : cur_addr;
  assign wr_data = (clearing | ~paint) ? 5'd0 : {selected_color, selected_brush};
endmodule