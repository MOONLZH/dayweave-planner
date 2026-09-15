import { getChatGPTUser } from '@/app/chatgpt-auth';
import { plannerDb } from '@/db';
import { emptyPlanner } from '@/lib/planner';
import { saveSchema } from '@/lib/validation';
export const dynamic = 'force-dynamic';
const json=(body:unknown,status=200)=>Response.json(body,{status,headers:{'Cache-Control':'no-store, private'}});
export async function GET(){
 const user=await getChatGPTUser();if(!user)return json({error:'请登录后查看自己的安排。'},401);
 try{
 const row=await plannerDb().prepare('SELECT state, revision FROM planner_workspaces WHERE owner_id = ?').bind(user.userId).first<{state:string;revision:number}>();
 return json({state:row?JSON.parse(row.state):emptyPlanner(),revision:row?.revision??0,user:{name:user.displayName}});
 }catch(error){console.error('planner load failed',error);return json({error:'暂时无法读取安排，请稍后重试。'},503);}
}
export async function PUT(request:Request){
 const user=await getChatGPTUser();if(!user)return json({error:'登录已过期，请重新登录。'},401);
 const origin=request.headers.get('origin');
 if((origin&&origin!==new URL(request.url).origin)||request.headers.get('sec-fetch-site')==='cross-site')return json({error:'请求来源无效。'},403);
 if(!request.headers.get('content-type')?.includes('application/json'))return json({error:'请求格式无效。'},415);
 try{
 const reader=request.body?.getReader();if(!reader)return json({error:'请求为空。'},400);
 let size=0;const parts:Uint8Array[]=[];
 while(true){const {value,done}=await reader.read();if(done)break;size+=value.byteLength;if(size>1800000){await reader.cancel();return json({error:'安排数据过大，请减少备注或任务数量。'},413);}parts.push(value);}
 const bytes=new Uint8Array(size);let offset=0;for(const p of parts){bytes.set(p,offset);offset+=p.length;}
 let payload;try{payload=JSON.parse(new TextDecoder().decode(bytes));}catch{return json({error:'请求内容无法解析。'},400);}
 const parsed=saveSchema.safeParse(payload);if(!parsed.success)return json({error:parsed.error.issues[0]?.message||'安排数据无效。'},400);
 const {state,revision}=parsed.data;
 const result=await plannerDb().prepare('INSERT INTO planner_workspaces (owner_id, state, revision, updated_at) SELECT ?, ?, 1, ? WHERE ? = 0 OR EXISTS (SELECT 1 FROM planner_workspaces WHERE owner_id = ?) ON CONFLICT(owner_id) DO UPDATE SET state = excluded.state, revision = planner_workspaces.revision + 1, updated_at = excluded.updated_at WHERE planner_workspaces.revision = ?').bind(user.userId,JSON.stringify(state),new Date().toISOString(),revision,user.userId,revision).run();
 if(result.meta.changes!==1)return json({error:'其他设备刚刚更新了安排。已为你刷新，请核对后再次保存。'},409);
 return json({revision:revision+1});
 }catch(error){console.error('planner save failed',error);return json({error:'保存未成功，你的输入仍在，请重试。'},503);}
}
