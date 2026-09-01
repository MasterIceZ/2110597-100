module clock_divider #(
  parameter integer DIVIDE = 10'd1000
) (
  input wire clk,
  input wire reset,

  output wire tick
);

  localparam integer W = $clog2(DIVIDE);

  reg [W-1:0] div;

  always @(posedge clk) begin
    if (reset) begin
      div <= 10'd0;
    end else if(tick) begin
      div <= 10'd0;
    end else begin
      div <= div + 1'b1;
    end
  end

  assign tick = (div >= DIVIDE - 1);
endmodule
