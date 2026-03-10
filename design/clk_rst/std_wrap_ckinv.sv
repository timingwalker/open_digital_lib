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
// Create Date   : 2019-12-20 10:29:01
// Last Modified : 2026-03-10 11:47:58
// Description   : standard cell wrapper
// ----------------------------------------------------------------------
module std_wrap_ckinv
(
    input  wire in_i,
    output wire zn_o
  );

`ifdef ASIC
    ERROR: please replace with standard cells herl!
`else
  assign zn_o = ~in_i;
`endif

endmodule
