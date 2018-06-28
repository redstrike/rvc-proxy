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

context.global.genStatTime=context.global.genStatTime || 0;
if(msg.hasOwnProperty('countdown')) {
    if(context.global.genStatTime===0 || (new Date().getTime()/1000)-context.global.genStatTime>5)
        return msg;
    else
        return null;
} else {
    context.global.genStatTime=new Date().getTime()/1000;
    return msg;
}

