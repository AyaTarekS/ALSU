import pkg::*;
module ALSU_tb ();
  logic clk;
  logic rst;
  //testbench Variables 
  int error_count, correct_count;
  logic signed [5:0] prev_out = 0;


  //ports declaration 
  logic signed [2:0] A, B;
  opcode_e opcode;
  opcode_e opcodes[6];
  logic signed [5:0] out;
  logic signed [1:0] cin;
  logic serial_in, direction;
  logic bypass_A, bypass_B;
  logic red_op_A, red_op_B;
  logic [15:0] leds;
  logic signed [5:0] expected_out_reg;
  ALUpkg pkg1 = new();

  //clock generation 
  initial begin
    clk = 0;
    forever begin
      #5 clk = ~clk;
      pkg1.clk = clk;
    end
  end

  //instance of the DUT
  ALSU DUT (.*);
  golden_model GM (.*);
  initial begin
    //reset the DUT
    assert_reset();
    //First loop
    //disable the 8th constraint
    pkg1.opcode_8.constraint_mode(0);
    repeat (1000) begin
      //randomize the inputs 
      assert (pkg1.randomize());
      //assign the inputs to the DUT
      A = pkg1.A;
      B = pkg1.B;
      opcode = pkg1.opcode;
      bypass_A = pkg1.bypass_A;
      bypass_B = pkg1.bypass_B;
      red_op_A = pkg1.red_op_A;
      red_op_B = pkg1.red_op_B;
      rst = pkg1.rst;
      serial_in = pkg1.serial_in;
      direction = pkg1.direction;
      cin = pkg1.cin;
      @(posedge clk);
      check_results(expected_out_reg, out);
    end
    //Second loop
    pkg1.constraint_mode(0);
    pkg1.rst = 1'b0;
    pkg1.bypass_A = 1'b0;
    pkg1.bypass_B = 1'b0;
    pkg1.red_op_A = 1'b0;
    pkg1.red_op_B = 1'b0;
    pkg1.opcode_8.constraint_mode(1);
    opcodes = '{OR , XOR , ADD , MULT , SHIFT , ROTATE};
    //nested loop
    repeat(1000)begin
        assert(pkg1.randomize());
        A = pkg1.A;
        B = pkg1.B;
        serial_in = pkg1.serial_in;
        direction = pkg1.direction;
        cin = pkg1.cin;
        foreach(opcodes[i]) begin
            pkg1.opcode = opcodes[i];
            //@(negedge clk);
            check_results(expected_out_reg, out);
        end
    end
    //print the results
    print();
    $finish();
  end
  task assert_reset();
    rst = 1'b1;
    repeat (2) @(negedge clk);
    if (out !== 0) begin
      $display("the reset is have an error");
      error_count++;
    end else correct_count++;
    rst = 1'b0;
  endtask


  task check_results(logic signed [5:0] expected_out, logic signed [5:0] actual_out);
    @(negedge clk);
    // Result verification
    if (expected_out !== actual_out) begin
      error_count++;
      $display(
          "Error: Test case failed - expected %b, got %b in operation %d with A : %b , B : %b bypassA: %0b and bypassB: %0b , and reduction flags:%0b , %0b ) ",
          expected_out, actual_out, DUT.opcode, DUT.A, DUT.B, DUT.bypass_A, DUT.bypass_B,
          DUT.red_op_A, DUT.red_op_B);
    end else begin
      correct_count++;
    end
  endtask
  task print();
    $display("the number of correct test cases is %0d", correct_count);
    $display("the number of error test cases is %0d", error_count);
  endtask
endmodule
