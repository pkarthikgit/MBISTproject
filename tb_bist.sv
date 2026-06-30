module tb_bist;
  //------------------------------------------------------------------
  // Parameters
  //------------------------------------------------------------------
  `define size   6
  `define length 8

  //------------------------------------------------------------------
  // Signals
  //------------------------------------------------------------------
  logic                clk;
  logic                rst;
  logic                start;
  logic                csin;
  logic                rwbarin;
  logic                opr;
  logic [`size-1:0]     address;
  logic [`length-1:0]   datain;
  logic [`length-1:0]   dataout;
  logic                fail;
  logic                NbarT;
  logic                ld;

  //------------------------------------------------------------------
  // Instantiate DUT
  //------------------------------------------------------------------
  bist #(.size(`size), .length(`length)) dut (
    .start    (start),
    .rst      (rst),
    .clk      (clk),
    .csin     (csin),
    .rwbarin  (rwbarin),
    .opr      (opr),
    .address  (address),
    .datain   (datain),
    .dataout  (dataout),
    .fail     (fail)
  );

  //------------------------------------------------------------------
  // Utility tasks
  //------------------------------------------------------------------
  task automatic check_normal(input [`length-1:0] exp_data);
    if (dataout !== exp_data) begin
      $display("FAIL normal @%0t: dataout exp=%h got=%h", $time, exp_data, dataout);
    end else begin
      $display("PASS normal @%0t: dataout=%h", $time, dataout);
    end
    if (fail !== 1'b0) begin
      $display("FAIL normal @%0t: fail should be 0, got %b", $time, fail);
    end
  endtask

  task automatic check_bist(input logic exp_ld, input logic exp_NbarT);
    if (ld !== exp_ld || NbarT !== exp_NbarT) begin
      $display("FAIL BIST @%0t: ld exp=%b NbarT exp=%b | got ld=%b NbarT=%b", $time,
               exp_ld, exp_NbarT, ld, NbarT);
    end else begin
      $display("PASS BIST @%0t: ld=%b NbarT=%b", $time, ld, NbarT);
    end
    if (fail !== 1'b0) begin
      $display("FAIL BIST @%0t: fail should be 0, got %b", $time, fail);
    end
  endtask

  //------------------------------------------------------------------
  // Clock generation
  //------------------------------------------------------------------
  initial clk = 0;
  always #5 clk = ~clk;

  //------------------------------------------------------------------
  // Stimulus
  //------------------------------------------------------------------
  initial begin
    // 1. Initial reset
    rst      = 1; start = 0;
    csin     = 0; rwbarin = 1;
    opr      = 0; address = '0; datain = '0;
    #20; @(posedge clk); rst = 0;

    // 2. Normal write to address 3
    csin     = 1; rwbarin = 0; address = 6'd3; datain = 8'hA5;
    @(posedge clk); #1 check_normal(8'h00); // write, dataout = 0

    // 3. Normal read back
    rwbarin  = 1; address = 6'd3;
    @(posedge clk); #1 check_normal(8'hA5);

    // 4. BIST mode entry
    start    = 1; opr = 0;
    @(posedge clk); #1 check_bist(1'b1, 1'b1); // ld pulses, NbarT=1
    start    = 0;

    // 5. BIST write cycles (ld=0,NbarT=1)
    repeat (2) begin
      @(posedge clk); #1 check_bist(1'b0,1'b1);
    end

    // 6. BIST read cycles (after 64 write cylces) not explicitly tested
    //    just ensure BIST remains enabled and no fail
    opr      = 1;
    repeat (2) begin
      @(posedge clk); #1 check_bist(1'b0,1'b1);
    end

    $display("BIST top integration tests completed.");
    $finish;
  end
endmodule
