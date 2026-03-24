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
// Description   : 
// ----------------------------------------------------------------------

module KEY_EXPAND(
    input               clk         ,
    input               rst_n       ,
    input   [127:0]     in          ,
    input               start_pos   ,
    input               key_update  ,
    input   [7:0]       rcon        ,
    output  [127:0]     out
);


reg   [127:0]  roundkey ;
wire  [31:0]   k0       ;
wire  [31:0]   k1       ;
wire  [31:0]   k2       ;
wire  [31:0]   k3       ;
wire  [31:0]   k0b      ;
wire  [31:0]   k1b      ;
wire  [31:0]   k2b      ;
wire  [31:0]   k3b      ;
wire  [7:0]    k3_0     ;
wire  [7:0]    k3_1     ;
wire  [7:0]    k3_2     ;
wire  [7:0]    k3_3     ;


always @ (posedge clk or negedge rst_n) begin
    if ( rst_n == 1'b0 ) begin
        roundkey <= 128'd0;
    end
    else if (key_update == 1'b1) begin
        if (start_pos == 1'b1) begin
            roundkey <= in;
        end
        else begin
            roundkey <= {k0b,k1b,k2b,k3b};
        end
    end
    else;
end

assign {k0, k1, k2, k3} = roundkey;

SBOX S_0(.in(k3[7:0]),.out(k3_0));
SBOX S_1(.in(k3[15:8]),.out(k3_1));
SBOX S_2(.in(k3[23:16]),.out(k3_2));
SBOX S_3(.in(k3[31:24]),.out(k3_3));

assign k0b = k0 ^ {k3_2,k3_1,k3_0,k3_3} ^ {rcon,24'd0};
assign k1b = k0b ^ k1;
assign k2b = k1b ^ k2;
assign k3b = k2b ^ k3;

assign out = roundkey;

endmodule
