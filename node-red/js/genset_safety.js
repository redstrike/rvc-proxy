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

if(!msg.hasOwnProperty('timer')) {
    if(msg.topic=='genstartenable') {
        if(msg.payload=="1") {
            context.global.genstartenabletimer=5;
            context.global.genstartenable=1;
        } else {
            context.global.genstartenabletimer=5;
            context.global.genstartenable=0;
        }
    } else {
        if(msg.topic=='generator' && msg.payload=='1' && context.global.genstartenable===1 ) {
            return msg;
        }
        if(msg.topic=='generator' && msg.payload==='0' && context.global.genstartenable===1 ) {
            return msg;
        }
    }
}
