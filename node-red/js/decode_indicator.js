// Copyright 2018 Wandertech LLC
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

var payload_parts=msg.payload.split(',');

state=0;
if(payload_parts[2]>0) {
    state=1;
    context.global.panelbrightness=payload_parts[2];
}


var msg0={
    'topic': payload_parts[0]+"_state",
    'payload': state,
    'external': 1,
}
var msg1={
    'topic': payload_parts[0],
    'payload': payload_parts[2],
    'external': 1,
};

if(payload_parts[0]==126)
    return [msg0, msg1];
