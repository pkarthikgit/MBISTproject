module sram(
  input  logic        clk,       // rising‐edge clock
  input  logic        cs,        // chip select (active high)
  input  logic        rwbar,     // 0 = write, 1 = read
  input  logic [5:0]  ramaddr,   // 6‐bit address
  input  logic [7:0]  ramin,     // write data
  output logic [7:0]  ramout     // read data
);

  // 1) Memory storage: 64 words of 8‐bits each
  logic [7:0] mem [0:63];

  // 2) Registered address for synchronous read
  logic [5:0] addr_reg;

  // 3) On each rising edge, if cs is asserted:
  //    a) capture the address into addr_reg
  //    b) if rwbar==0, write ramin into mem at ramaddr
  always_ff @(posedge clk) begin
    if (cs) begin
      addr_reg <= ramaddr;
      if (~rwbar) begin
        mem[ramaddr] <= ramin;
      end
    end
  end

  // 4) Combinational read output:
  //    If cs==1 and rwbar==1, drive the output from mem at addr_reg,
  //    otherwise drive all zeros.
  assign ramout = (cs && rwbar) ? mem[addr_reg] : 8'b0;

endmodule
