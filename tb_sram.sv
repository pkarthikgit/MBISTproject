module tb_sram;
  //------------------------------------------------------------------
  // Parameters
  //------------------------------------------------------------------
  `define AW 6
  `define DW 8

  //------------------------------------------------------------------
  // Signals
  //------------------------------------------------------------------
  logic                 clk;
  logic                 cs;
  logic                 rwbar;
  logic [`AW-1:0]        ramaddr;
  logic [`DW-1:0]        ramin;
  logic [`DW-1:0]        ramout;

  //------------------------------------------------------------------
  // Instantiate DUT
  //------------------------------------------------------------------
  sram ut (
    .clk     (clk),
    .cs      (cs),
    .rwbar   (rwbar),
    .ramaddr (ramaddr),
    .ramin   (ramin),
    .ramout  (ramout)
  );

  //------------------------------------------------------------------
  // Utility: PASS/FAIL reporter
  //------------------------------------------------------------------
  task automatic check_ramout(input logic [`DW-1:0] exp_data);
    if (ramout !== exp_data) begin
      $display("FAIL\tTime=%0t\t exp=%h | got=%h | cs=%b rwbar=%b addr=%0d ramin=%h", $time, exp_data, ramout, cs, rwbar, ramaddr, ramin);
    end else begin
      $display("PASS\tTime=%0t\t exp=%h | got=%h | cs=%b rwbar=%b addr=%0d ramin=%h", $time, exp_data, ramout, cs, rwbar, ramaddr, ramin);
    end
  endtask

  //------------------------------------------------------------------
  // Clock generation
  //------------------------------------------------------------------
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100 MHz
  end

  //------------------------------------------------------------------
  // Stimulus
  //------------------------------------------------------------------
  initial begin
    // 1) Initial: idle, read mode
    cs      = 0; rwbar = 1; ramaddr = 6'd10; ramin = 8'hAA;
    #1; check_ramout(8'h00);

    // 2) Write A1 = 10, data = A5
    cs      = 1; rwbar = 0; ramaddr = 6'd10; ramin = 8'hA5;
    @(posedge clk);
    #1; check_ramout(8'h00);  // still write mode

    // 3) Read back A1
    rwbar   = 1; cs = 1; ramaddr = 6'd20;  // change addr input
    #1; check_ramout(8'hA5);  // uses addr_reg=10

    // 4) Write A2 = 20, data = 5A
    cs      = 1; rwbar = 0; ramaddr = 6'd20; ramin = 8'h5A;
    @(posedge clk);
    #1; check_ramout(8'h00);

    // 5) Read back A2
    rwbar   = 1; cs = 1; ramaddr = 6'd0;  // new addr input
    #1; check_ramout(8'h5A);

    // 6) Read back A1 again via new cycle
    rwbar   = 1; cs = 1; ramaddr = 6'd10;
    @(posedge clk);
    #1; check_ramout(8'hA5);

    // 7) CS deassert -> output should 0
    cs      = 0;
    #1; check_ramout(8'h00);

    $display("All SRAM tests completed.");
    $finish;
  end
endmodule
