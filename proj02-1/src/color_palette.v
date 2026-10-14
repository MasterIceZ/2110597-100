module color_palette(
  input wire [2:0] index,

  output reg [5:0] rgb
);

  always @(*) begin
    case (index)
      3'd1: rgb = 6'b111111;
      3'd2: rgb = 6'b110000;
      3'd3: rgb = 6'b111000;
      3'd4: rgb = 6'b111100;
      3'd5: rgb = 6'b001100;
      3'd6: rgb = 6'b010111;
      3'd7: rgb = 6'b110011;
      default: rgb = 6'b000000;
    endcase
  end

endmodule