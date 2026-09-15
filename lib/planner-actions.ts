import { addDays, type Planner, type Entry } from './planner';
export function moveEntry(state:Planner,id:string,date:string):Planner {
 const entry=state.entries.find(e=>e.id===id);if(!entry)throw new Error('这条记录已不存在，请刷新。');
 if(entry.date===date)return state;
 if(state.entries.some(e=>e.taskId===entry.taskId&&e.date===date))throw new Error('该任务在目标日期已有安排，请编辑那一天的记录。');
 const order=Math.max(-1,...state.entries.filter(e=>e.date===date).map(e=>e.order))+1;
 return expandProjects({...state,entries:state.entries.map(e=>e.id===id?{...e,date,order}:e)});
}
export function reorderEntries(state:Planner,date:string,ids:string[]):Planner {
 const current=state.entries.filter(e=>e.date===date);
 if(ids.length!==current.length||new Set(ids).size!==ids.length||ids.some(id=>!current.some(e=>e.id===id)))throw new Error('当天安排已变化，请重新排序。');
 const positions=new Map(ids.map((id,i)=>[id,i]));
 return {...state,entries:state.entries.map(e=>positions.has(e.id)?{...e,order:positions.get(e.id)!}:e)};
}
export function expandProjects(state:Planner):Planner {
 return {...state,projects:state.projects.map(p=>{const tasks=new Set(state.tasks.filter(t=>t.projectId===p.id).map(t=>t.id));const dates=state.entries.filter(e=>tasks.has(e.taskId)).map(e=>e.date);return {...p,start:[p.start,...dates].sort()[0],end:[p.end,...dates].sort().at(-1)!};})};
}
export function rangeDates(start:string,end:string){
 if(start>end)throw new Error('结束日期不能早于开始日期。');
 const days:string[]=[];for(let d=start;d<=end;d=addDays(d,1)){if(days.length>=366)throw new Error('一次最多安排 366 天，请分阶段规划。');days.push(d);}return days;
}
export function normalizeNewOrders(state:Planner,rows:Entry[]):Entry[]{
 const max=new Map<string,number>();for(const e of state.entries)max.set(e.date,Math.max(max.get(e.date)??-1,e.order));
 return rows.map(e=>{const existing=state.entries.find(x=>x.id===e.id);if(existing?.date===e.date)return {...e,order:existing.order};const order=(max.get(e.date)??-1)+1;max.set(e.date,order);return {...e,order};});
}
