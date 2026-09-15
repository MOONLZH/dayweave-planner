import { z } from 'zod';
export const validDate = (v:string) => /^\d{4}-\d{2}-\d{2}$/.test(v) && v >= '1900-01-01' && v <= '2100-12-31' && !Number.isNaN(Date.parse(v)) && new Date(v).toISOString().slice(0,10)===v;
const date=z.string().refine(validDate,'请输入有效日期（1900—2100 年）');
const id=z.string().min(1).max(80).regex(/^[a-zA-Z0-9_-]+$/);
const title=z.string().trim().min(1,'请填写名称').max(200,'名称最多 200 字');
const note=z.string().max(10000,'备注最多 10000 字');
export const plannerSchema=z.object({
 projects:z.array(z.object({id,name:title,color:z.string().regex(/^#[0-9a-fA-F]{6}$/),start:date,end:date,note}).strict()).max(300),
 tasks:z.array(z.object({id,projectId:id,title,note,deadline:date.nullable()}).strict()).max(5000),
 entries:z.array(z.object({id,taskId:id,date,title,note,minutes:z.number().int().min(1).max(1440).nullable(),done:z.boolean(),order:z.number().int().min(0).max(1000000)}).strict()).max(12000),
}).strict().superRefine((data,ctx)=>{
 const issue=(message:string)=>ctx.addIssue({code:z.ZodIssueCode.custom,message});
 for(const [name,rows] of [['项目',data.projects],['任务',data.tasks],['每日记录',data.entries]] as const){if(new Set(rows.map(r=>r.id)).size!==rows.length)issue(`${name}编号重复`);}
 const ps=new Map(data.projects.map(p=>[p.id,p])),ts=new Map(data.tasks.map(t=>[t.id,t])),dates=new Set<string>();
 for(const p of data.projects)if(p.start>p.end)issue('项目结束日期不能早于开始日期');
 for(const t of data.tasks)if(!ps.has(t.projectId))issue('任务所属项目不存在');
 for(const e of data.entries){
 const t=ts.get(e.taskId),p=t?ps.get(t.projectId):undefined;
 if(!t)issue('每日记录所属任务不存在');
 if(p&&(e.date<p.start||e.date>p.end))issue('项目周期需要包含全部每日安排');
 const key=e.taskId+':'+e.date;if(dates.has(key))issue('同一任务在同一天只能有一条记录');dates.add(key);
 }
 const scheduled=new Set(data.entries.map(e=>e.taskId));
 for(const t of data.tasks)if(!scheduled.has(t.id))issue('任务至少需要安排一天');
});
export const saveSchema=z.object({revision:z.number().int().min(0).max(Number.MAX_SAFE_INTEGER-1),state:plannerSchema}).strict();
