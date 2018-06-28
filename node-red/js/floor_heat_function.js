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

var newMsg={};
if(external===0) {
    var floors=context.global.floors || {
        0:{'power':0, 'setpoint': 65, 'measured': 0},
        1:{'power':0, 'setpoint': 65, 'measured': 0},
    };
    if ( msg.topic.match(/_state$/)) {
        topic_parts=msg.topic.split('_');
        if(msg.payload===1) {
            newMsg={
                'payload': topic_parts[0]+' '+floors[topic_parts[0]].setpoint
            };
        } else {
            newMsg={
                'payload': topic_parts[0]+' 0'
            };
        }
    } else {
        var newMsg={
            'instance': msg.topic,
            'command': msg.payload,
            'payload': msg.topic+' '+msg.payload,
            'external': external,
            };
    }
    return newMsg;
}
