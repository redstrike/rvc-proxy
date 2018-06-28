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

var topic_parts=msg.topic.split('/');
var payload_parts=msg.payload.split(',');

var topic=1;

command=0;
if(topic_parts[1]==35 && payload_parts[1]==100.0)
    command=1;
if(topic_parts[1]==36 && payload_parts[1]==100.0)
    command=2;

levels=['Off','Low','High'];

var msg1={
    'payload':levels[command]
};

var msg2={
    'topic': topic,
    'payload': command,
    'external': 1,
};

return [ msg1, msg2 ];
