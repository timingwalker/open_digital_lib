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

module MIXCOLUNM (
    input   [31:0]  in  ,
    output  [31:0]  out  
);

wire    [7:0]       s0  ;
wire    [7:0]       s1  ;
wire    [7:0]       s2  ;
wire    [7:0]       s3  ;
wire    [7:0]       s0b ;
wire    [7:0]       s1b ;
wire    [7:0]       s2b ;
wire    [7:0]       s3b ;

assign {s0, s1, s2, s3} = in;

xtimes U1( .in(s0^s1), .out(s0b) );
xtimes U2( .in(s1^s2), .out(s1b) );
xtimes U3( .in(s2^s3), .out(s2b) );
xtimes U4( .in(s3^s0), .out(s3b) );

assign out[31:24] = s0b ^ s1 ^ s2 ^ s3;
assign out[23:16] = s1b ^ s0 ^ s2 ^ s3;
assign out[15:8]  = s2b ^ s0 ^ s1 ^ s3;
assign out[7:0]   = s3b ^ s0 ^ s1 ^ s2;

endmodule


module xtimes(
    input     [7:0]     in  ,
    output    [7:0]     out                 
);

assign out = (in[7] == 1'b0) ? (in << 1'b1) : ((in << 1'b1) ^ 8'h1b) ;

endmodule 

