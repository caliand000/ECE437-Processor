module pipe_reg #(
  parameter type T = logic [31:0]
)(
  input logic CLK,
  input logic nRST,
  input logic en,
  input logic flush,
  input T d,
  output T q
);
  always_ff @(posedge CLK, negedge nRST) begin
    if(!nRST)
      q <= '0;
    else if(flush)
      q <= '0;
    else if(en)
      q <= d;
  end
endmodule
