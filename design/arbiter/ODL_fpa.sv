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
// Create Date   : 2025-12-26 10:29:01
// Last Modified : 2026-01-26 11:47:58
// Description   : weighted round robin arbiter
// ----------------------------------------------------------------------

module ODL_fpa #(
    parameter int NUM_PORT = 8
)(
    input  logic [NUM_PORT-1:0]     req_i
   ,output logic [NUM_PORT-1:0]     gnt_o
);

    logic [NUM_PORT-1:0] higher_pri_reqs;

    assign higher_pri_reqs[0]            = 1'b0;
    assign higher_pri_reqs[NUM_PORT-1:1] = higher_pri_reqs[NUM_PORT-2:0] | req_i[NUM_PORT-2:0];
    assign gnt_o[NUM_PORT-1:0]           = req_i[NUM_PORT-1:0] & ~higher_pri_reqs[NUM_PORT-1:0];

endmodule

