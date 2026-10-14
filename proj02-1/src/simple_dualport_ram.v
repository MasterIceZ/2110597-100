module simple_dualport_ram #(
  parameter AW,
  parameter DEPTH,
  parameter DW
) (
  input wire clk,
  input wire we,
  input wire [AW-1:0] wr_addr,
  input wire [DW-1:0] wr_data,
  input wire [AW-1:0] rd_addr,
  
  output reg [DW-1:0] rd_data
);

  reg [DW-1:0] mem [0:DEPTH-1];

  always @(posedge clk) begin
    if (we) begin
      mem[wr_addr] <= wr_data;
    end
    rd_data <= mem[rd_addr];
  end
endmodule