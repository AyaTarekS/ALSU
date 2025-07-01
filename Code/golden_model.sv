import pkg::*;
  module golden_model(
    input logic signed [2:0] A, 
    input logic signed [2:0] B,
    input opcode_e opcode,
    input logic signed [1:0] cin,
    input logic bypass_A,
    input logic bypass_B,
    input logic red_op_A,
    input logic red_op_B,
    input logic direction,
    input logic serial_in,
    input logic rst,
    input logic clk,
    output logic signed [5:0] expected_out_reg
  );
  reg signed [2:0] A_reg, B_reg;
  opcode_e opcode_reg;
  reg bypass_A_reg, bypass_B_reg;
  reg red_op_A_reg, red_op_B_reg;
  reg direction_reg;
  reg serial_in_reg;
  reg signed [1:0] cin_reg;

  
  always @(posedge clk , posedge rst)begin
  if(rst)begin
    A_reg <= 0;
    B_reg <= 0;
    bypass_A_reg <= 0;
    bypass_B_reg <= 0;
    red_op_A_reg <= 0;
    red_op_B_reg <= 0;
    direction_reg <= 0;
    serial_in_reg <= 0;
    cin_reg <= 0;
    opcode_reg <= OR;
  end
  else begin
    A_reg <= A;
    B_reg <= B;
    bypass_A_reg <= bypass_A;
    bypass_B_reg <= bypass_B;
    red_op_A_reg <= red_op_A;
    red_op_B_reg <= red_op_B;
    direction_reg <= direction;
    serial_in_reg <= serial_in;
    cin_reg <= cin;
    opcode_reg <= opcode;
  end
  end
  always @(posedge clk , posedge rst)begin
    if(rst)begin
        expected_out_reg <= 0;
    end
  else begin
    if(bypass_A_reg) 
        expected_out_reg = {{3{A_reg[2]}}, A_reg};
    else if(bypass_B_reg)
        expected_out_reg = {{3{B_reg[2]}}, B_reg};
    else begin
        // Reduction operation check
        if ((red_op_A_reg || red_op_B_reg) && !(opcode_reg==OR||opcode_reg==XOR)) begin
            expected_out_reg = 6'b000000;
        end
        else if (opcode_reg == INVALID_6 || opcode_reg == INVALID_7) begin
            expected_out_reg = 6'b000000;
        end
        else begin
            // Main operation decoder
            case (opcode_reg)
                OR: begin
                    if (red_op_A_reg) begin
                        expected_out_reg = {5'b0 , |A_reg};
                    end
                    else if (red_op_B_reg) begin
                        expected_out_reg = {5'b0 , |B_reg};
                    end
                    else begin
                        expected_out_reg = A_reg | B_reg;
                    end
                end
                
                XOR: begin
                    if (red_op_A_reg == 1) begin
                        expected_out_reg = {5'b0 , ^A_reg};
                    end
                    else if (red_op_B_reg == 1) begin
                        expected_out_reg = {5'b0 , ^B_reg};
                    end
                    else begin
                        expected_out_reg = A_reg ^ B_reg;
                    end
                end
                ADD: begin
                    expected_out_reg = A_reg + B_reg + cin_reg; 
                end
                MULT: begin
                    expected_out_reg = A_reg * B_reg;
                end
                SHIFT: begin 
                    if (direction_reg == 1) begin
                        expected_out_reg = {expected_out_reg[4:0], serial_in_reg};
                    end 
                    else begin
                        expected_out_reg = {serial_in_reg, expected_out_reg[5:1]};
                    end
                end
                ROTATE: begin
                    if (direction_reg == 1) begin
                        expected_out_reg = {expected_out_reg[4:0], expected_out_reg[5]};
                    end 
                    else begin
                        expected_out_reg = {expected_out_reg[0], expected_out_reg[5:1]};
                    end
                end

                default: expected_out_reg = 6'b000000; // Default case for safety

            endcase // opcode switch-case block

        end 

    end 
  end

  end
  endmodule // golden_model