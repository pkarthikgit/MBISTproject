module counter #(parameter LENGTH = 10)
(
    input  logic [LENGTH-1:0] d_in,
    input  logic              clk,
    input  logic              ld,
    input  logic              u_d,     // 1 = up, 0 = down
    input  logic              cen,     // count enable
    output logic [LENGTH-1:0] q,
    output logic              cout     // overflow/underflow flag
);

  // 10‑bit counter storage
  logic [LENGTH-1:0] count;

  // One‑bit‑wider temporary for arithmetic so MSB becomes overflow flag
  logic [LENGTH:0]   temp;

  always_ff @(posedge clk) begin
    if (!cen) begin
      // Hold value, clear cout when disabled
      cout <= 1'b0;
    end else if (ld) begin
      // Load
      count <= d_in;
      cout  <= 1'b0;
    end else begin
      // Up or Down counting with overflow/underflow detection
      if (u_d) begin
        temp = {1'b0, count} + 1'b1;   // increment
      end else begin
        temp = {1'b0, count} - 1'b1;   // decrement
      end

      count <= temp[LENGTH-1:0];  // keep lower 10 bits
      cout  <= temp[LENGTH];      // MSB is overflow (1 on wrap)
    end
  end

  assign q = count;

endmodule
