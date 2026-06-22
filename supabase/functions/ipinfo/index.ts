// Supabase Edge Function: 获取客户端IP和地区信息
// 部署：supabase functions deploy ipinfo

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type, x-client-info, apikey'
}

serve(async (req) => {
  // 处理 CORS 预检请求
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 获取客户端真实IP（优先取 x-forwarded-for）
    const forwarded = req.headers.get('x-forwarded-for')
    const ip = forwarded ? forwarded.split(',')[0].trim() : ''

    // 调用 ipwho.is 获取地区信息
    const resp = await fetch('https://ipwho.is/' + (ip ? encodeURIComponent(ip) : ''), {
      signal: AbortSignal.timeout(3000)
    })
    const data = await resp.json()

    if (data.success) {
      return new Response(
        JSON.stringify({
          ip: data.ip || ip,
          city: data.city || '',
          region: data.region || '',
          country: data.country || '',
          location: [data.city, data.region, data.country].filter(Boolean).join(' · ')
        }),
        { headers: { 'Content-Type': 'application/json', ...corsHeaders } }
      )
    }

    // API失败时返回仅有IP的信息
    return new Response(
      JSON.stringify({ ip, city: '', region: '', country: '', location: '' }),
      { headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    )
  } catch (e) {
    return new Response(
      JSON.stringify({ ip: '', city: '', region: '', country: '', location: '', error: String(e) }),
      { headers: { 'Content-Type': 'application/json', ...corsHeaders }, status: 500 }
    )
  }
})
