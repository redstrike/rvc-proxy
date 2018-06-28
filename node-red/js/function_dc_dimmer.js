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

var loads = context.loads|| {
    1:[3,100],  // Main
    2:[3,100],  // Entry
    3:[3,100],  // PS Ceiling
    4:[3,100],  // DS Ceiling
    5:[3,100],  // Mid Hall [optional]
    6:[3,100],  // PS Slide
    7:[3,100],  // PS Sconce
    8:[3,100],  // DS Slide
    9:[3,100],  // DS Sconce
    10:[3,100], // Bed Reading
    11:[3,100], // Bed Sconce
    12:[3,100], // Bed Ceiling
    13:[3],     // Master Bath Ceiling
    14:[3],     // Kitchen Task
    15:[3],     // Half Bath Ceiling
    16:[3],     // Half Bath Vanity
    17:[3],     // Master Bath Vanity
    18:[3],     // TV Accent [optional]
    19:[3],     // Front Accent
    20:[3],     // Rear Accent [optional]
    21:[3],     // Road Light
    22:[3],     // Porch Light
    23:[3],     // Electric AquaHot
    24:[3],     // Diesel AquaHot
    28:[3],     // Closet Light
    91:[3],     // Porch 2 [??]
    93:[3],     // Water Pump
    95:[3],     // Door Light
    96:[3],     // Cargo Lights
};

var external=0;
if(msg.hasOwnProperty('external'))
    external=msg.external;


var topic_parts=msg.topic.split('_');
var command=0;
var brightness=loads[topic_parts[0]][1] || 100;

if(loads[topic_parts[0]]) {
    if(topic_parts[1]=='state') {
        loads[topic_parts[0]][0]=msg.payload;
        command=msg.payload;
    } else if(topic_parts[1]=='brightness') {
        brightness=msg.payload;
        if(brightness>0) {
            command=0;
            loads[topic_parts[0]][1]=msg.payload;
        }
    }
}

var newMsg={
    'instance': topic_parts[0],
    'command': command,
    'brightness': brightness,
    'payload': topic_parts[0]+' '+command+' '+brightness,
    'external': external,
    };
context.loads=loads;

if(external===0) {
    return newMsg;
}
