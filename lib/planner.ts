export type Project = { id: string; name: string; color: string; start: string; end: string; note: string };
export type Task = { id: string; projectId: string; title: string; note: string; deadline: string | null };
export type Entry = { id: string; taskId: string; date: string; title: string; note: string; minutes: number | null; done: boolean; order: number };
export type Planner = { projects: Project[]; tasks: Task[]; entries: Entry[] };
export const COLORS = ['#6258d7', '#278fa0', '#df8b34', '#d45e8e', '#3c78bd', '#57834b'];
export const emptyPlanner = (): Planner => ({ projects: [], tasks: [], entries: [] });
export function dateKey(d = new Date()) { return new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Shanghai',year:'numeric',month:'2-digit',day:'2-digit'}).format(d); }
export function addDays(date: string, n: number) { const d = new Date(date+'T12:00:00Z'); d.setUTCDate(d.getUTCDate()+n); return d.toISOString().slice(0,10); }
export function dayLabel(date: string) { const d = new Date(date+'T12:00:00'); return `${d.getMonth()+1}月${d.getDate()}日`; }
export function monday(date: string) { const d = new Date(date+'T12:00:00'); return addDays(date,-((d.getDay()+6)%7)); }
export function minutesLabel(n: number) { return n >= 60 ? `${Number((n/60).toFixed(1))} 小时` : `${n} 分钟`; }
export function sortedEntries(data: Planner, date: string) { return data.entries.filter(e=>e.date===date).sort((a,b)=>a.order-b.order || a.id.localeCompare(b.id)); }
export function samplePlanner(today: string): Planner {
 const w=monday(today), d=(n:number)=>addDays(today,n);
 const projects:Project[]=[
 {id:'p1',name:'品牌官网改版',color:COLORS[0],start:addDays(w,-3),end:addDays(w,16),note:'梳理品牌表达，完成官网设计与交付。'},
 {id:'p2',name:'秋季活动策划',color:COLORS[1],start:w,end:addDays(w,11),note:'活动物料、报名页面与上线准备。'},
 {id:'p3',name:'个人作品集',color:COLORS[2],start:addDays(w,2),end:addDays(w,23),note:'整理案例，让作品的思考过程更清晰。'}];
 const tasks:Task[]=[
 {id:'t1',projectId:'p1',title:'首页设计',note:'先确定信息层级，再完善视觉细节。',deadline:d(3)},
 {id:'t2',projectId:'p2',title:'确认活动主视觉',note:'和文案一起核对标题与日期。',deadline:d(1)},
 {id:'t3',projectId:'p3',title:'整理作品集案例',note:'补充项目背景与个人负责部分。',deadline:null},
 {id:'t4',projectId:'p1',title:'同步设计评审意见',note:'把待确认的问题记录到任务中。',deadline:null},
 {id:'t5',projectId:'p2',title:'核对报名页文案',note:'检查按钮文案和提交成功提示。',deadline:d(2)},
 {id:'t6',projectId:'p1',title:'整理竞品参考',note:'筛选 3 个值得参考的导航方案。',deadline:null}];
 const entries:Entry[]=[
 {id:'e1',taskId:'t1',date:today,title:'完成首页结构与首屏设计',note:'优先确定导航结构，保留两版首屏方案。',minutes:120,done:false,order:0},
 {id:'e2',taskId:'t2',date:today,title:'确认活动主视觉',note:'下午反馈前，先核对主标题。',minutes:45,done:false,order:1},
 {id:'e3',taskId:'t3',date:today,title:'整理作品集案例',note:'先从最近完成的两个项目开始。',minutes:90,done:false,order:2},
 {id:'e4',taskId:'t4',date:today,title:'同步设计评审意见',note:'',minutes:30,done:true,order:3},
 {id:'e5',taskId:'t5',date:today,title:'核对报名页文案',note:'',minutes:null,done:false,order:4},
 {id:'e6',taskId:'t1',date:d(1),title:'完善首页视觉细节',note:'',minutes:120,done:false,order:0},
 {id:'e7',taskId:'t1',date:d(2),title:'完成响应式设计与交付',note:'',minutes:90,done:false,order:0},
 {id:'e8',taskId:'t3',date:d(3),title:'补充案例设计过程',note:'',minutes:90,done:false,order:0},
 {id:'e9',taskId:'t6',date:d(-1),title:'整理竞品参考',note:'保留原计划，重新安排合适的时间。',minutes:45,done:false,order:0}];
 for(const p of projects){const dates=entries.filter(e=>tasks.some(t=>t.id===e.taskId&&t.projectId===p.id)).map(e=>e.date);p.start=[p.start,...dates].sort()[0];}
 return {projects,tasks,entries};
}
