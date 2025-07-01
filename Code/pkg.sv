package pkg;
typedef enum bit [2:0] {OR , XOR , ADD , MULT , SHIFT , ROTATE , INVALID_6 , INVALID_7} opcode_e;
parameter MAXPOS = 7;
parameter MAXNEG = -8;
parameter ZERO = 0;
  class ALUpkg;
    rand bit rst, bypass_A , bypass_B;
    rand bit signed [2:0] A , B ;
    randc opcode_e opcode;
    rand bit red_op_A , red_op_B;
    rand bit direction; 
    rand bit serial_in ;
    rand bit signed [1:0] cin;
    logic clk;
    //constraint 1
    constraint reset_c{
        rst dist {1:=15, 0:=85};
    }
    //constraint 2
    constraint opcode_c{
        opcode dist {[OR:ROTATE]:/98,[INVALID_6:INVALID_7]:=2};    
        }
    //constraint 3
constraint input_c {
        (opcode == ADD) -> 
            A dist {
                MAXPOS  :/ 20,  // 20% chance of maximum positive
                MAXNEG  :/ 20,  // 20% chance of maximum negative  
                ZERO    :/ 20,  
                [-7:-1] :/ 20,  
                [1:6]   :/ 20   
            };
            cin dist {0:=50, 1:=50};
        (opcode == ADD) ->
            B dist {
                MAXPOS  :/ 20,
                MAXNEG  :/ 20,
                ZERO    :/ 20,
                [-7:-1] :/ 20,
                [1:6]   :/ 20
            };
        
        (opcode == MULT) ->
            A dist {
                MAXPOS  :/ 10,  
                MAXNEG  :/ 10,  
                ZERO    :/ 10,  
                [-7:-1] :/ 35,  
                [1:6]   :/ 35   
            };
        (opcode == MULT)->
            B dist {
                MAXPOS  :/ 10,
                MAXNEG  :/ 10,
                ZERO    :/ 10,
                [-7:-1] :/ 35,
                [1:6]   :/ 35
            };

    //constraint 4
    serial_in dist {1:=50, 0:=50};
    //constraint 5
    direction dist {1:=50, 0:=50};

}
    //constraint 6
    constraint reduction_c{
        (opcode == OR || opcode == XOR) -> {
            (red_op_A == 1) ->{
                A dist {
                    3'b001:=25,
                    3'b010:=25,
                    3'b100:=25
                };
                B == ZERO;
            }
            (red_op_A == 0) -> {
                A == ZERO;
                B dist {
                    3'b001:=25,
                    3'b010:=25,
                    3'b100:=25
                };
            }
        }
}
    //constraint 7
    constraint bypass_c{
        bypass_A dist{1:=20, 0:=80};
        bypass_B dist{1:=20, 0:=80};
    }
    //constraint 8
    constraint opcode_8{
            opcode inside {OR , XOR , ADD , MULT , SHIFT , ROTATE};
    }
    covergroup alu_cg @(posedge clk);
    A_cp: coverpoint A {
        bins A_data_0 = {0};
        bins A_data_max = {MAXPOS};
        bins A_data_min = {MAXNEG};
        bins A_data_default = {[-7:6]};
        bins A_data_walkingones ={[1:4]} with (red_op_A == 1);
        //to ignore the 3'b011
        ignore_bins A_data_walkingones_red = {3} with(red_op_A == 1);
    }
    B_cp: coverpoint B {
        bins B_data_0 = {0};
        bins B_data_max = {MAXPOS};
        bins B_data_min = {MAXNEG};
        bins B_data_default = {[-7:6]};
        bins B_data_walkingones ={[1:3]} with (red_op_B == 1 && red_op_A ==0);
        ignore_bins B_data_walkingones_red = {3} with(red_op_B == 1 && red_op_A ==0);
    }
        opcode_cp: coverpoint opcode {
            bins Bins_Arith[]={[ADD:MULT]};
            bins Bins_bitwise[]={[OR:XOR]};
            bins Bins_shift[]={[SHIFT:ROTATE]};
            illegal_bins Bins_invalid[]={[INVALID_6:INVALID_7]};
            bins Bins_trans = (OR => XOR => ADD => MULT => SHIFT => ROTATE);
}
    
        arthmetic_A: coverpoint A iff(opcode == ADD || opcode == MULT){
            bins Adata0 = {0};
            bins Adatamax = {MAXPOS};
            bins Adatamin = {MAXNEG};
        }
        arthmetic_B: coverpoint B iff(opcode == ADD || opcode == MULT){
            bins bdata1 = {0};
            bins bdata2 = {MAXPOS};
            bins bdata3 = {MAXNEG};
        }
        crossinput: cross arthmetic_A, arthmetic_B{
            bins a0b0 = binsof(arthmetic_A.Adata0) && binsof(arthmetic_B.bdata1);
            bins a0bmax = binsof(arthmetic_A.Adata0) && binsof(arthmetic_B.bdata2);
            bins a0bmin = binsof(arthmetic_A.Adata0) && binsof(arthmetic_B.bdata3);
            bins amaxb0 = binsof(arthmetic_A.Adatamax) && binsof(arthmetic_B.bdata1);
            bins amaxbmax = binsof(arthmetic_A.Adatamax) && binsof(arthmetic_B.bdata2);
            bins amaxbmin = binsof(arthmetic_A.Adatamax) && binsof(arthmetic_B.bdata3);
            bins aminb0 = binsof(arthmetic_A.Adatamin) && binsof(arthmetic_B.bdata1);
            bins aminbmax = binsof(arthmetic_A.Adatamin) && binsof(arthmetic_B.bdata2);
            bins aminbmin = binsof(arthmetic_A.Adatamin) && binsof(arthmetic_B.bdata3);
        }
        cincoverage: coverpoint cin iff(opcode == ADD){
            bins cin_0 = {0};
            bins cin_1 = {1};
            ignore_bins cin_2 = {-2,-1};
        }
        direction_cp: coverpoint direction iff(opcode == SHIFT || opcode == ROTATE){
            bins dir_0 = {0};
            bins dir_1 = {1};
        }
        serial_in_cp: coverpoint serial_in iff(opcode == SHIFT){
            bins serial_in_0 = {0};
            bins serial_in_1 = {1};
        }
        reduction_A_cp: coverpoint A iff(red_op_A == 1 && (opcode == OR || opcode == XOR)){
            bins A_reddata_1 = {3'b001};
            bins A_reddata_2 = {3'b010};
            bins A_reddata_3 = {3'b100};
        }
        reduction_A:cross reduction_A_cp, B_cp{
            bins A_data_1_red = binsof(reduction_A_cp.A_reddata_1) && binsof(B_cp.B_data_0);
            bins A_data_2_red = binsof(reduction_A_cp.A_reddata_2) && binsof(B_cp.B_data_0);
            bins A_data_3_red = binsof(reduction_A_cp.A_reddata_3) && binsof(B_cp.B_data_0);
        }
        reduction_B_cp: coverpoint B iff(red_op_B == 1 && red_op_A == 0 && (opcode == OR || opcode == XOR)){
            bins B_reddata_1 = {3'b001};
            bins B_reddata_2 = {3'b010};
            bins B_reddata_3 = {3'b100};
        }
        reduction_B: cross reduction_B_cp, A_cp{
            bins B_data_1_red = binsof(reduction_B_cp.B_reddata_1) && binsof(A_cp.A_data_0);
            bins B_data_2_red = binsof(reduction_B_cp.B_reddata_2) && binsof(A_cp.A_data_0);
            bins B_data_3_red = binsof(reduction_B_cp.B_reddata_3) && binsof(A_cp.A_data_0);
        }
        invalidcases: coverpoint opcode {
            bins invalid = {[ADD:INVALID_7]} with (red_op_A == 1 || red_op_B == 1);
        }


    endgroup
    function new();
        alu_cg = new();
    endfunction
endclass  
endpackage
// 
// 
