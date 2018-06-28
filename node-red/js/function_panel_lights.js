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

var external=0;
if(msg.hasOwnProperty('external'))
    external=msg.external;

if(msg.topic=="126_state") {
    msg.topic=126;
    if(msg.payload==1)
        msg.payload=context.global.panelbrightness || 100;
} else {
    if(msg.payload>0 && external===0)
        context.global.panelbrightness=msg.payload;
}


if(external===0) {
    var newMsg={
        'instance': msg.topic,
        'command': msg.payload,
        'payload': msg.topic+' '+msg.payload,
        'external': external,
        };
    return newMsg;
}
