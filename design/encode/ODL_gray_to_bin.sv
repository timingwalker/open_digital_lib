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
// Create Date   : 2026-03-23 21:07:30
// Last Modified : 2026-03-23 21:14:30
// Description   : Gray to binary
// ----------------------------------------------------------------------

module ODL_gray_to_bin #(
    parameter int WIDTH = 8
)(
    input  logic [WIDTH-1:0]     gray_i
   ,output logic [WIDTH-1:0]     bin_o
);

    assign bin_o[WIDTH-1] = gray_i[WIDTH-1];
    for (genvar i=0; i<WIDTH-1; i++) begin : gen_gray_to_bin
        assign bin_o[i] = gray_i[i] ^ bin_o[i+1];
    end

endmodule

