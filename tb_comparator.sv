module tb_comparator;
  `define WIDTH  8

  // DUT interface signals
  logic [`WIDTH-1:0] data_t, ramout;
  logic             gt, eq, lt;

  // Instantiate DUT
  comparator #(.WIDTH(`WIDTH)) dut (
    .data_t (data_t),
    .ramout (ramout),
    .gt     (gt),
    .eq     (eq),
    .lt     (lt)
  );

  //------------------------------------------------------------------
  // Utility: pass/fail reporter
  //------------------------------------------------------------------
  task automatic check_output(input logic exp_gt, input logic exp_eq, input logic exp_lt);
    if (gt !== exp_gt || eq !== exp_eq || lt !== exp_lt) begin
      $display("FAIL\tTime=%0t\t Expected gt:%b eq:%b lt:%b | Got gt:%b eq:%b lt:%b", $time, exp_gt, exp_eq, exp_lt, gt, eq, lt);
    end else begin
      $display("PASS\tTime=%0t\t Expected gt:%b eq:%b lt:%b | Got gt:%b eq:%b lt:%b", $time, exp_gt, exp_eq, exp_lt, gt, eq, lt);
    end
  endtask

  //------------------------------------------------------------------
  // Stimulus (purely combinational, no clock)
  //------------------------------------------------------------------
  initial begin
    //--------------------------------------------------------------
    // 1) Fixed functional cases
    //--------------------------------------------------------------
    data_t = 8'd10; ramout = 8'd5;  #1;  check_output(1,0,0); // greater
    data_t = 8'd20; ramout = 8'd20; #1;  check_output(0,1,0); // equal
    data_t = 8'd7;  ramout = 8'd15; #1;  check_output(0,0,1); // less

    //--------------------------------------------------------------
    // 2) Edge extremes
    //--------------------------------------------------------------
    data_t = 8'hFF; ramout = 8'h00; #1;  check_output(1,0,0); // max vs min
    data_t = 8'h00; ramout = 8'hFF; #1;  check_output(0,0,1); // min vs max

    //--------------------------------------------------------------
    // 3) Random trials
    //--------------------------------------------------------------
    repeat (10) begin
      void'(std::randomize(data_t));
      void'(std::randomize(ramout));
      #1;
      if (data_t > ramout)       check_output(1,0,0);
      else if (data_t == ramout) check_output(0,1,0);
      else                       check_output(0,0,1);
    end

    //--------------------------------------------------------------
    // Finish
    //--------------------------------------------------------------
    $display("All comparator tests completed.");
    $finish;
  end
endmodule
