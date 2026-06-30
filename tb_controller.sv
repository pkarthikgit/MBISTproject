module tb_controller;
  //=================================================================
  // Local parameters and typedefs
  //=================================================================
  typedef enum logic [1:0] {RESET_ST = 2'b00, TEST_ST = 2'b01} state_t;

  //=================================================================
  // Signals
  //=================================================================
  logic start, rst, clk, cout;
  logic NbarT, ld;
  state_t ref_state, next_ref_state;

  // DUT instantiation
  controller dut (
    .start  (start),
    .rst    (rst),
    .clk    (clk),
    .cout   (cout),
    .NbarT  (NbarT),
    .ld     (ld)
  );

  //=================================================================
  // Reference FSM for checking
  //=================================================================
  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      ref_state <= RESET_ST;
    else
      ref_state <= next_ref_state;
  end

  always_comb begin
    // defaults
    next_ref_state = RESET_ST;
    case (ref_state)
      RESET_ST: next_ref_state = start ? TEST_ST : RESET_ST;
      TEST_ST : next_ref_state = cout  ? RESET_ST : TEST_ST;
    endcase
  end

  //=================================================================
  // Check task
  //=================================================================
  task automatic check_fsm(input state_t exp_state);
    logic exp_NbarT, exp_ld;
    // expected outputs by state
    exp_NbarT = (exp_state == TEST_ST);
    exp_ld     = (exp_state == RESET_ST);

    if (NbarT !== exp_NbarT || ld !== exp_ld) begin
      $display("FAIL\tT=%0t\t State=%b | Exp NbarT=%b ld=%b | Got NbarT=%b ld=%b", 
               $time, exp_state, exp_NbarT, exp_ld, NbarT, ld);
    end else begin
      $display("PASS\tT=%0t\t State=%b | NbarT=%b ld=%b", $time, exp_state, NbarT, ld);
    end
  endtask

  //=================================================================
  // Clock generation
  //=================================================================
  initial clk = 0;
  always #5 clk = ~clk; // 100 MHz clock

  //=================================================================
  // Stimulus sequence
  //=================================================================
  initial begin
    // initial values
    start = 0; cout = 0; rst = 1;
    // wait two cycles under reset
    repeat (2) @(posedge clk);
    rst = 0;

    // 1) At RESET, ld should be 1, NbarT=0
    @(posedge clk); check_fsm(RESET_ST);

    // 2) Assert start=1 -> move to TEST
    start = 1;
    @(posedge clk); check_fsm(TEST_ST);

    // deassert start
    start = 0;

    // 3) Stay in TEST while cout=0
    repeat (2) begin
      cout = 0;
      @(posedge clk); check_fsm(TEST_ST);
    end

    // 4) Assert cout=1 -> go back to RESET
    cout = 1;
    @(posedge clk); check_fsm(RESET_ST);

    // 5) Ensure in RESET: ld=1, NbarT=0
    console:// no op
    @(posedge clk); check_fsm(RESET_ST);

    // 6) Toggle start again and verify cycle
    start = 1; cout = 0;
    @(posedge clk); check_fsm(TEST_ST);
    start = 0;

    // final read
    #10 $display("All controller FSM tests completed.");
    $finish;
  end
endmodule
