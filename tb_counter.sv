module tb_counter;
  `define LENGTH 10

  //------------------------------------------------------------------
  // DUT interface signals
  //------------------------------------------------------------------
  logic [`LENGTH-1:0] d_in, q;
  logic               clk, ld, u_d, cen, cout;
  logic [`LENGTH-1:0] count;

  // Instantiate DUT
  counter #(.LENGTH(`LENGTH)) dut (.*);

  //------------------------------------------------------------------
  // Utility: PASS / FAIL reporter
  //------------------------------------------------------------------
  task automatic check_output(input logic exp_cout);
    if (q !== count || cout !== exp_cout) begin
      $display("FAIL\tT=%0t\tExp q:%b cout:%b | Got q:%b cout:%b", $time, count, exp_cout, q, cout);
    end else begin
      $display("PASS\tT=%0t\tExp q:%b cout:%b | Got q:%b cout:%b", $time, count, exp_cout, q, cout);
    end
  endtask

  //------------------------------------------------------------------
  // Clock
  //------------------------------------------------------------------
  initial clk = 0;
  always   #5 clk = ~clk;   // 100 MHz

  //------------------------------------------------------------------
  // Stimulus
  //------------------------------------------------------------------
  initial begin
    //--------------------------------------------------------------
    // Reset / Init
    //--------------------------------------------------------------
    ld = 0; d_in = '0; cen = 0; u_d = 0; count = '0;

    //--------------------------------------------------------------
    // 0) Random LOAD while cen = 1
    //--------------------------------------------------------------
    #4; cen = 1; ld = 1; void'(std::randomize(count)); d_in = count;
    #2  check_output(1'b0);

    //--------------------------------------------------------------
    // 1) Hold with cen = 0
    //--------------------------------------------------------------
    cen = 0; void'(std::randomize(d_in)); #10 check_output(1'b0);

    //--------------------------------------------------------------
    // 2) Release ld, still held (cen = 0)
    //--------------------------------------------------------------
    ld = 0; #10 check_output(1'b0);

    //--------------------------------------------------------------
    // 3) Single INC, then DEC
    //--------------------------------------------------------------
    cen  = 1; u_d = 1; count = count + 1; #10 check_output(1'b0);
    u_d  = 0; count = count - 1; #10 check_output(1'b0);

    //--------------------------------------------------------------
    // 4) Under‑flow wrap (already in original TB)
    //--------------------------------------------------------------
    ld = 1; count = '0; d_in = count; #10 check_output(1'b0);
    u_d = 0; ld = 0; count = count - 1; #10 check_output(1'b1);
    u_d = 1; count = count + 1; #10 check_output(1'b1);
    count = count + 1;          #10 check_output(1'b0);

    //--------------------------------------------------------------
    // 5) ***NEW*** Overflow wrap and clear
    //--------------------------------------------------------------
    // 5a) Load max value
    ld   = 1; count = {`LENGTH{1'b1}}; d_in = count; #10 check_output(1'b0);
    // 5b) Increment to wrap -> expect cout pulse
    ld   = 0; u_d = 1; count = '0; #10 check_output(1'b1);
    // 5c) Increment again -> cout must clear
    count = count + 1;           #10 check_output(1'b0);

    //--------------------------------------------------------------
    // 6) Disable counting, hold outputs
    //--------------------------------------------------------------
    cen = 0; u_d = 1;  @(posedge clk); check_output(1'b0);
    u_d = 0;            @(posedge clk); check_output(1'b0);

    //--------------------------------------------------------------
    // 7) Load with cen = 0 (should be ignored)
    //--------------------------------------------------------------
    ld = 1; d_in = 10'd123; @(posedge clk); check_output(1'b0);

    //--------------------------------------------------------------
    // 8) Re‑enable and finish
    //--------------------------------------------------------------
    ld = 0; cen = 1; u_d = 0; // down‑count one step
    count = count - 1;            // advance reference before edge
    @(posedge clk);
    check_output(1'b0);

    #10 $finish;
  end
endmodule
