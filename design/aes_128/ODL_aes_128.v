// ----------------------------------------------------------------------
// Copyright 2026 TimingWalker
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ----------------------------------------------------------------------
// Create Date   : 2018
// Last Modified : 2026-03-24 21:39:27
// Description   : aes-128 core
// ----------------------------------------------------------------------

module ODL_aes_128(
    input                   clk     ,
    input                   rst_n   ,
    input                   start   ,
    input       [127:0]     data_in , // input
    input       [127:0]     key_in  , // cipher key
    output      [127:0]     out       // output

);

wire [127:0]        in              ;
wire                start_pos       ;
wire                start_pos_1d    ;
wire                key_update      ;
wire                state_update    ;
wire                isLastRound     ; // last round flag, bypass mixcolunm transformation
wire     [7:0]      rcon            ;
wire     [127:0]    key_out         ; // round key
wire     [127:0]    addRoundKeyOut  ; // output of addRoundKey transformation
wire     [127:0]    mixColunmOut    ; // output of mixColunm transformation
reg      [127:0]    state           ; // State matrix
wire     [7:0]      s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15;                  // State matrix
wire     [7:0]      s0b,s1b,s2b,s3b,s4b,s5b,s6b,s7b,s8b,s9b,s10b,s11b,s12b,s13b,s14b,s15b;  // output of SubBytes transformation
wire     [7:0]      s0c,s1c,s2c,s3c,s4c,s5c,s6c,s7c,s8c,s9c,s10c,s11c,s12c,s13c,s14c,s15c;  // output of mixColunm transformation


assign in = data_in;

// ctrl logic
CTRL U_CTRL(
    .clk            (clk)           ,
    .rst_n          (rst_n)         ,
    .start          (start)         ,
    .start_pos      (start_pos)     ,
    .start_pos_1d   (start_pos_1d)  ,
    .key_update     (key_update)    ,
    .state_update   (state_update)  ,
    .isLastRound    (isLastRound)   ,
    .rcon           (rcon)
);

// expand round key
KEY_EXPAND U_KEY_EXPAND(
    .clk            (clk)           ,
    .rst_n          (rst_n)         ,
    .in             (key_in)        ,
    .start_pos      (start_pos)     ,
    .key_update     (key_update)    ,
    .rcon           (rcon)          ,
    .out            (key_out)   
);

// addRoundKey transformation
assign addRoundKeyOut = ((start_pos_1d == 1'b1) ? in : mixColunmOut) ^ key_out;

// state matrix register
always @ ( posedge clk or negedge rst_n) begin
    if ( rst_n == 1'b0) begin
        state <= 128'd0;
    end
    else if (state_update == 1'b1) begin
        state <= addRoundKeyOut;
    end
    else;
end

// alias of state matrix
assign {s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15} = state[127:0];
    
// SubBytes transformation
SBOX S_0(.in(s0),.out(s0b));
SBOX S_1(.in(s1),.out(s1b));
SBOX S_2(.in(s2),.out(s2b));
SBOX S_3(.in(s3),.out(s3b));
SBOX S_4(.in(s4),.out(s4b));
SBOX S_5(.in(s5),.out(s5b));
SBOX S_6(.in(s6),.out(s6b));
SBOX S_7(.in(s7),.out(s7b));
SBOX S_8(.in(s8),.out(s8b));
SBOX S_9(.in(s9),.out(s9b));
SBOX S_10(.in(s10),.out(s10b));
SBOX S_11(.in(s11),.out(s11b));
SBOX S_12(.in(s12),.out(s12b));
SBOX S_13(.in(s13),.out(s13b));
SBOX S_14(.in(s14),.out(s14b));
SBOX S_15(.in(s15),.out(s15b));

// mixColunm transformation
MIXCOLUNM U_MIXCOLUNM_1 (.in({s0b,s5b,s10b,s15b}), .out({s0c,s1c,s2c,s3c})      );
MIXCOLUNM U_MIXCOLUNM_2 (.in({s4b,s9b,s14b,s3b} ), .out({s4c,s5c,s6c,s7c})      );
MIXCOLUNM U_MIXCOLUNM_3 (.in({s8b,s13b,s2b,s7b} ), .out({s8c,s9c,s10c,s11c})    );
MIXCOLUNM U_MIXCOLUNM_4 (.in({s12b,s1b,s6b,s11b}), .out({s12c,s13c,s14c,s15c})  );

// output of mixColunm, the last round is bypassed.
assign  mixColunmOut[127:0] = ( isLastRound == 1'b0 ) ? 
                              {s0c,s1c,s2c,s3c,s4c,s5c,s6c,s7c,s8c,s9c,s10c,s11c,s12c,s13c,s14c,s15c} :
                              {s0b,s5b,s10b,s15b,s4b,s9b,s14b,s3b,s8b,s13b,s2b,s7b,s12b,s1b,s6b,s11b} ;

// output
assign out = state;
                                
endmodule

