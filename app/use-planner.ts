'use client';
import { useCallback, useEffect, useRef, useState } from 'react';
import { toast } from 'sonner';
import { emptyPlanner, samplePlanner, type Planner } from '@/lib/planner';
import { plannerSchema } from '@/lib/validation';
export function usePlanner(today:string){
 const [data,setData]=useState<Planner>(()=>samplePlanner(today));
 const [demo,setDemo]=useState(false),[ready,setReady]=useState(false),[busy,setBusy]=useState(false),[online,setOnline]=useState(true),[authenticated,setAuthenticated]=useState(true),[error,setError]=useState(''),[name,setName]=useState('个人工作空间');
 const current=useRef({data,revision:0,demo:false,ready:false,busy:false}),pause=useRef(false),generation=useRef(0);
 const apply=useCallback((state:Planner,revision:number,isDemo:boolean)=>{current.current={...current.current,data:state,revision,demo:isDemo,ready:true};setData(state);setDemo(isDemo);setReady(true);},[]);
 const refresh=useCallback(async(initial=false)=>{
 if(!initial&&(current.current.busy||current.current.demo||pause.current))return;
 const requestId=++generation.current;
 try{
 const response=await fetch('/api/planner',{cache:'no-store',signal:AbortSignal.timeout(15000)});
 if(response.status===401){setAuthenticated(false);if(initial)apply(samplePlanner(today),0,true);return;}
 const payload=await response.json() as {state:unknown;revision:number;user:{name:string};error?:string};if(!response.ok)throw new Error(payload.error||'暂时无法同步，请重试。');
 if(requestId!==generation.current||(!initial&&(current.current.busy||pause.current||current.current.demo)))return;
 if(payload.revision>=current.current.revision){const checked=plannerSchema.parse(payload.state);apply(initial&&!checked.projects.length?samplePlanner(today):checked,payload.revision,initial&&!checked.projects.length);}
 setName(payload.user.name);setAuthenticated(true);setOnline(true);setError('');
 }catch(e){if(initial&&!current.current.ready){current.current.data=emptyPlanner();setData(emptyPlanner());}setOnline(false);setError(e instanceof Error?e.message:'暂时无法同步，请重试。');}
 },[apply,today]);
 useEffect(()=>{void refresh(true);const timer=setInterval(()=>{if(document.visibilityState==='visible')void refresh();},8000);const resume=()=>{if(document.visibilityState==='visible')void refresh();};window.addEventListener('focus',resume);window.addEventListener('online',resume);document.addEventListener('visibilitychange',resume);return()=>{clearInterval(timer);window.removeEventListener('focus',resume);window.removeEventListener('online',resume);document.removeEventListener('visibilitychange',resume);generation.current++;};},[refresh]);
 const commit=useCallback(async(change:(s:Planner)=>Planner,message='已保存')=>{
 if(current.current.busy||!current.current.ready)return false;
 let next:Planner;try{next=plannerSchema.parse(change(current.current.data));}catch(e){toast.error(e instanceof Error?('issues' in e ? '请检查日期、名称和每日安排。':e.message):'请检查输入。');return false;}
 if(current.current.demo){apply(next,current.current.revision,true);toast.success('示例已更新，不会保存到你的安排');return true;}
 current.current.busy=true;setBusy(true);generation.current++;
 try{
 const response=await fetch('/api/planner',{method:'PUT',headers:{'Content-Type':'application/json'},body:JSON.stringify({state:next,revision:current.current.revision}),signal:AbortSignal.timeout(20000)});
 const payload=await response.json() as {state:unknown;revision:number;user:{name:string};error?:string};
 if(response.status===409){const latest=await fetch('/api/planner',{cache:'no-store'});if(latest.ok){const value=await latest.json() as {state:unknown;revision:number};apply(plannerSchema.parse(value.state),value.revision,false);}throw new Error(payload.error||'请刷新后重试。');}
 if(response.status===401){setAuthenticated(false);throw new Error(payload.error||'请刷新后重试。');}
 if(!response.ok)throw new Error(payload.error||'保存失败，请重试。');
 apply(next,payload.revision,false);setOnline(true);setError('');toast.success(message);return true;
 }catch(e){toast.error(e instanceof Error?e.message:'保存未成功，输入已保留。');return false;}
 finally{current.current.busy=false;setBusy(false);}
 },[apply]);
 const startOwn=()=>{if(!authenticated)return false;apply(emptyPlanner(),current.current.revision,false);setError('');return true;};
 return {data,demo,ready,busy,online,authenticated,error,name,commit,refresh,startOwn,pause};
}
