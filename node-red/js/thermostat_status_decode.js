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

var topic_parts=msg.topic.split('/');
var payload_parts=msg.payload.split(',');

var floors=context.global.floors || {
    0:{'power':0, 'setpoint': 65, 'measured': 0},
    1:{'power':0, 'setpoint': 65, 'measured': 0},
};

var zones={
    0:'Front',
    1:'Rear',
};

if(topic_parts[0]=='THERMOSTAT_AMBIENT_STATUS') {
    if(topic_parts[1] in floors) {
        var temp_parts=payload_parts[0].split('.');
        floors[topic_parts[1]].measured=temp_parts[0];
        context.global.floors=floors;
        var status={
            'topic': topic_parts[1],
            'zone': zones[topic_parts[1]],
            'status': floors[topic_parts[1]].measured+' F',
            'payload':floors[topic_parts[1]].measured,
            'external': 1,
        };
        delete msg.payload;
        delete msg.topic;
        return [status,null,null];
    }
} else {
    var temp_parts=payload_parts[3].split('.');
    floors[topic_parts[1]].setpoint=temp_parts[0];
    floors[topic_parts[1]].power=0;
    if(payload_parts[0]!='Off') {
        floors[topic_parts[1]].power=1;
    }

    context.global.floors=floors;
    var setpoint={
        'topic': topic_parts[1],
        'zone': zones[topic_parts[1]],
        'payload': temp_parts[0],
        'status': floors[topic_parts[1]].measured+' F',
        'external': 1,
    };
    delete msg.payload;
    delete msg.topic;

    return [null,{'topic':topic_parts[1], 'payload':floors[topic_parts[1]].power},setpoint];
}
