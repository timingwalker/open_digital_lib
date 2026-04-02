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
// Create Date   : 2026-03-25 22:08:05
// Last Modified : 2026-04-03 00:19:12
// Description   : 
// ----------------------------------------------------------------------

// 5x5 Array Multiplier Module (Baugh-Wooley Architecture)
// Features:
// - Supports unsigned (mode=0) and signed (mode=1, two's complement) multiplication
// - Input: 5-bit X, 5-bit Y; Output: 10-bit product P
// - Mode control: 0 = unsigned, 1 = signed (Baugh-Wooley two's complement correction)
module ODL_mult_array_55 (
    input  logic [4:0] X,     // 5-bit multiplier input
    input  logic [4:0] Y,     // 5-bit multiplicand input
    input  logic       mode,  // Operation mode: 0=unsigned, 1=signed
    output logic [9:0] P      // 10-bit product output
);

// Partial Products (X[i] AND Y[j], i=row, j=column)
logic pp00, pp01, pp02, pp03, pp04;
logic pp10, pp11, pp12, pp13, pp14;
logic pp20, pp21, pp22, pp23, pp24;
logic pp30, pp31, pp32, pp33, pp34;
logic pp40, pp41, pp42, pp43, pp44;

// Assign partial products (ppij = X[i] & Y[j])
assign pp00 = X[0]&Y[0];
assign pp01 = X[0]&Y[1];
assign pp02 = X[0]&Y[2];
assign pp03 = X[0]&Y[3];
assign pp04 = (X[0]&Y[4]) ^ mode;  // Corrected: pp04 with mode correction (signed mode)

assign pp10 = X[1]&Y[0];
assign pp11 = X[1]&Y[1];
assign pp12 = X[1]&Y[2];
assign pp13 = X[1]&Y[3];
assign pp14 = X[1]&Y[4];

assign pp20 = X[2]&Y[0];
assign pp21 = X[2]&Y[1];
assign pp22 = X[2]&Y[2];
assign pp23 = X[2]&Y[3];
assign pp24 = X[2]&Y[4];

assign pp30 = X[3]&Y[0];
assign pp31 = X[3]&Y[1];
assign pp32 = X[3]&Y[2];
assign pp33 = X[3]&Y[3];
assign pp34 = X[3]&Y[4];

assign pp40 = X[4]&Y[0];
assign pp41 = X[4]&Y[1];
assign pp42 = X[4]&Y[2];
assign pp43 = X[4]&Y[3];
assign pp44 = X[4]&Y[4];

// Baugh-Wooley Two's Complement Correction Signals
// For signed multiplication (mode=1), correct the sign bits of partial products
logic pp14_c, pp24_c, pp34_c;
logic pp40_c, pp41_c, pp42_c, pp43_c;

assign pp14_c = pp14 ^ mode;
assign pp24_c = pp24 ^ mode;
assign pp34_c = pp34 ^ mode;

assign pp40_c = pp40 ^ mode;
assign pp41_c = pp41 ^ mode;
assign pp42_c = pp42 ^ mode;
assign pp43_c = pp43 ^ mode;

// CSA (Carry-Save Adder) Array Signals
// s[1-4][0-4]: Sum outputs of CSA rows
// c[1-4][0-4]: Carry outputs of CSA rows
logic s10, s11, s12, s13, s14;
logic s20, s21, s22, s23, s24;
logic s30, s31, s32, s33, s34;
logic s40, s41, s42, s43, s44;

logic c10, c11, c12, c13, c14;
logic c20, c21, c22, c23, c24;
logic c30, c31, c32, c33, c34;
logic c40, c41, c42, c43, c44;

// CSA Row 1 (Half Adders)
// Accumulate partial products from row 1 and row 0
HA h1_0(.a(pp14_c), .b(mode),   .s(s10), .co(c10));
HA h1_1(.a(pp13),   .b(pp04),   .s(s11), .co(c11));
HA h1_2(.a(pp12),   .b(pp03),   .s(s12), .co(c12));
HA h1_3(.a(pp11),   .b(pp02),   .s(s13), .co(c13));
HA h1_4(.a(pp10),   .b(pp01),   .s(s14), .co(c14));

// CSA Row 2 (Full Adders)
// Accumulate partial products from row 2 + sum/carry from row 1
FA f2_0(.a(pp24_c), .b(1'b0), .ci(c10), .s(s20), .co(c20));
FA f2_1(.a(pp23),   .b(s10),  .ci(c11), .s(s21), .co(c21));
FA f2_2(.a(pp22),   .b(s11),  .ci(c12), .s(s22), .co(c22));
FA f2_3(.a(pp21),   .b(s12),  .ci(c13), .s(s23), .co(c23));
FA f2_4(.a(pp20),   .b(s13),  .ci(c14), .s(s24), .co(c24));

// CSA Row 3 (Full Adders)
// Accumulate partial products from row 3 + sum/carry from row 2
FA f3_0(.a(pp34_c), .b(1'b0), .ci(c20), .s(s30), .co(c30));
FA f3_1(.a(pp33),   .b(s20),  .ci(c21), .s(s31), .co(c31));
FA f3_2(.a(pp32),   .b(s21),  .ci(c22), .s(s32), .co(c32));
FA f3_3(.a(pp31),   .b(s22),  .ci(c23), .s(s33), .co(c33));
FA f3_4(.a(pp30),   .b(s23),  .ci(c24), .s(s34), .co(c34));

// CSA Row 4 (Full Adders)
// Accumulate partial products from row 4 (corrected) + sum/carry from row 3
FA f4_0(.a(pp44),   .b(1'b0), .ci(c30), .s(s40), .co(c40));
FA f4_1(.a(pp43_c), .b(s30),  .ci(c31), .s(s41), .co(c41));
FA f4_2(.a(pp42_c), .b(s31),  .ci(c32), .s(s42), .co(c42));
FA f4_3(.a(pp41_c), .b(s32),  .ci(c33), .s(s43), .co(c43));
FA f4_4(.a(pp40_c), .b(s33),  .ci(c34), .s(s44), .co(c44));

// CPA (Carry-Propagate Adder) Stage
// Final carry-propagate addition for CSA outputs
logic cp1, cp2, cp3, cp4;  // Carry signals between CPA stages

FA cpa0(.a(s43), .b(c44), .ci(1'b0), .s(P[5]), .co(cp1));
FA cpa1(.a(s42), .b(c43), .ci(cp1),  .s(P[6]), .co(cp2));
FA cpa2(.a(s41), .b(c42), .ci(cp2),  .s(P[7]), .co(cp3));
FA cpa3(.a(s40), .b(c41), .ci(cp3),  .s(P[8]), .co(cp4));
// CPA4 configuration as confirmed (a=c40, b=mode, ci=cp4, co unconnected)
FA cpa4(.a(c40), .b(mode), .ci(cp4),  .s(P[9]), .co());

// Assign lower bits of product (directly from partial products/CSA sums)
assign P[0] = pp00;  // LSB of product (direct partial product)
assign P[1] = s14;   // CSA row 1 sum output
assign P[2] = s24;   // CSA row 2 sum output
assign P[3] = s34;   // CSA row 3 sum output
assign P[4] = s44;   // CSA row 4 sum output

endmodule

