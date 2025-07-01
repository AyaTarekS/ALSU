module ALSU_SVA(
    input logic signed [2:0] A , B,
    input logic signed [1:0] cin, 
    input bit serial_in , red_op_A , red_op_B,
    input bit [2:0] opcode ,
    input bit bypass_A , bypass_B , clk , rst , direction ,
    input logic [15:0] leds,
    input logic signed [5:0] out
);
int x; 
assign x = cin;
    //reset
    always_comb begin
        if(rst)
            assert final (out == 0);
    end
    sequence reduction_or_A;
        opcode == 0 && red_op_A;
    endsequence
    sequence reduction_xor_A;
        opcode == 1 && red_op_A;
    endsequence
    sequence reduction_or_B;
        opcode == 0 && !red_op_A && red_op_B ;
    endsequence
    sequence reduction_xor_B;
        opcode == 0 && !red_op_A && red_op_B ;
    endsequence
    sequence invalid;
        opcode == 6 || opcode == 7 || ((opcode[1]||opcode[2])&&(red_op_A||red_op_B));
    endsequence
    sequence invalid_bypA;
        (opcode == 6 || opcode == 7 || ((opcode[1]||opcode[2])&&(red_op_A||red_op_B)) )&& bypass_A;
    endsequence
    sequence invalid_bypB;
        (opcode == 6 || opcode == 7 || ((opcode[1]||opcode[2])&&(red_op_A||red_op_B)) )&& ~bypass_A && bypass_B ;
    endsequence
    //ALSU_2
    property add;
        @(posedge clk) disable iff(rst||bypass_A||bypass_B||red_op_A||red_op_B) opcode ==  2 |-> ##2 (out == $past(A,2)+$past(B,2)+$past(x,2));
    endproperty
    //ALSU_3
    property mul;
        @(posedge clk) disable iff(rst||bypass_A||bypass_B||red_op_A||red_op_B) opcode == 3 |-> ##2 (out == $past(A,2) * $past(B,2));
    endproperty
    //ALSU_4
    property orreduction_A;
        @(posedge clk) disable iff(rst||bypass_A||bypass_B) reduction_or_A |-> ##2 (out == |$past(A,2));
    endproperty
    property xorreduction_A;
        @(posedge clk) disable iff(rst||bypass_A||bypass_B) reduction_xor_A |-> ##2 (out == ^$past(A,2));
    endproperty
    //Alsu_5
    property orreduction_B;
        @(posedge clk) disable iff(rst||bypass_A||bypass_B) reduction_or_B |-> ##2 (out == |$past(B,2));
    endproperty
    property xorreduction_B;
        @(posedge clk) disable iff(rst||bypass_A||bypass_B) reduction_xor_B |-> ##2 (out == ^$past(B,2));
    endproperty
    //ALSU_6
    property invalid_low;
        @(posedge clk) disable iff(rst ||bypass_A||bypass_B ) invalid  |-> ##2 (out == 0);
    endproperty
    //ALSU_7
    // property invalid_bypassA;
    //     @(posedge clk) disable iff(rst) invalid_bypA |-> ##2 (out == $past(A,2));
    // endproperty
    //ALSU_8
    // property invalid_bypassB;
    //     @(posedge clk) disable iff(rst) invalid_bypB|-> (out == $past(B,2));
    // endproperty
    //other functionalities
    property OR;
        @(posedge clk) disable iff(rst||bypass_A||bypass_B||red_op_A||red_op_B) opcode == 0 |-> ##2(out == $past(A,2)|| $past(B,2));
    endproperty    
    property XOR;
        @(posedge clk) disable iff(rst||bypass_A||bypass_B||red_op_A||red_op_B) opcode == 1 |-> ##2(out == $past(A,2) ^ $past(B,2));
    endproperty
    property passing_A;
        @(posedge clk) disable iff(rst) bypass_A |-> ##2 out == $past(A,2);
    endproperty
    property passing_B;
        @(posedge clk) disable iff(rst) !bypass_A && bypass_B |-> ##2 out == $past(B,2);
    endproperty

assert property(add);
assert property(mul);
assert property(OR);
assert property(XOR);
assert property(passing_A);
assert property(passing_B);
//assert property(invalid_bypassA);
//assert property(invalid_bypassB);
assert property(invalid_low);
assert property(orreduction_A);
assert property(xorreduction_A);
assert property(orreduction_B);
assert property(xorreduction_B);

cover final (out == 0);
cover property(add);
cover property(mul);
cover property(OR);
cover property(XOR);
cover property(passing_A);
cover property(passing_B);
//cover property(invalid_bypassA);
//cover property(invalid_bypassB);
cover property(invalid_low);
cover property(orreduction_A);
cover property(xorreduction_A);
cover property(orreduction_B);
cover property(xorreduction_B);






endmodule