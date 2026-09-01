module randomizer
#(
  parameter integer RANGE = 640,
  parameter [15:0] SEED = 16'hABCD,
  parameter [15:0] TAPS = 16'hF812
) (
  input wire clk,
  input wire reset,
  input wire enable,

  output wire [9:0] rnd
);
  reg [15:0] lfsr;
  wire [31:0] scaled = lfsr * RANGE;
  always @(posedge clk) begin
    if (reset) begin
      lfsr <= SEED;
    end else if (enable) begin
      lfsr <= lfsr[0] ? {1'b0, lfsr[15:1]} ^ TAPS
                      : {1'b0, lfsr[15:1]};
    end
  end

  assign rnd = scaled[25:16];
endmodule