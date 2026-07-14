-- ============================================================
-- ICONE · Arquitecto de Ecosistema — BACKEND ADITIVO
-- Proyecto Supabase: docadmin (nvgkhdrrxqdgxktfkioa)
-- SEGURO: solo CREATE IF NOT EXISTS. No toca icone_evaluaciones
-- ni ninguna tabla/RPC existente. Nombres nuevos, sufijo _eco.
-- Pegar completo en: Supabase > SQL Editor > Run
-- ============================================================

create table if not exists public.icone_diagnosticos_eco (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  origen text not null default 'arquitecto-ecosistema',
  -- Bloque A · perfil
  nombre text, email text, rol text, sector text, equipo text,
  -- Bloque B · madurez
  membresias jsonb, antiguedad text, frecuencia text,
  madurez int, ya_hecho jsonb, ecosistema text, frenos jsonb,
  -- Bloque C · trabajo
  tareas jsonb, tareas_libres jsonb, tiempo text, horas numeric,
  dolor text, entregables jsonb, plantillas text,
  confidencialidad text, presupuesto text, meta_2h text,
  -- calculado
  nivel text, ruta text, stack jsonb, score int, meta jsonb
);

alter table public.icone_diagnosticos_eco enable row level security;
drop policy if exists "anon insert eco" on public.icone_diagnosticos_eco;
create policy "anon insert eco" on public.icone_diagnosticos_eco
  for insert to anon with check (true);
grant insert on table public.icone_diagnosticos_eco to anon;
grant insert on table public.icone_diagnosticos_eco to authenticated;

-- Panel privado: listado completo
create or replace function public.get_diagnosticos_eco(pass text)
returns setof public.icone_diagnosticos_eco
language plpgsql security definer set search_path=public as $$
begin
  if pass is distinct from 'Diagnosticos2026' then raise exception 'unauthorized'; end if;
  return query select * from public.icone_diagnosticos_eco order by created_at desc;
end; $$;

-- Panel privado: borrar un registro
create or replace function public.delete_diagnostico_eco(pass text, rid uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
  if pass is distinct from 'Diagnosticos2026' then raise exception 'unauthorized'; end if;
  delete from public.icone_diagnosticos_eco where id = rid;
end; $$;

-- Dashboard público: solo agregados, cero datos personales
create or replace function public.get_stats_eco()
returns jsonb language plpgsql security definer set search_path=public as $$
declare res jsonb; n int;
begin
  select count(*) into n from public.icone_diagnosticos_eco;
  select jsonb_build_object(
    'total', n,
    'updated_at', now(),
    'horas_prom', (select round(avg(horas)::numeric,1) from public.icone_diagnosticos_eco),
    'madurez_prom', (select round(avg(madurez)::numeric,2) from public.icone_diagnosticos_eco),
    'niveles', (select jsonb_object_agg(k,c) from (
        select coalesce(nivel,'—') k, count(*) c from public.icone_diagnosticos_eco group by 1) s),
    'rutas', (select jsonb_object_agg(k,c) from (
        select coalesce(ruta,'—') k, count(*) c from public.icone_diagnosticos_eco group by 1) s),
    'sectores', (select jsonb_object_agg(k,c) from (
        select coalesce(nullif(trim(sector),''),'—') k, count(*) c
        from public.icone_diagnosticos_eco group by 1 order by 2 desc limit 12) s),
    'presupuesto', (select jsonb_object_agg(k,c) from (
        select coalesce(presupuesto,'—') k, count(*) c from public.icone_diagnosticos_eco group by 1) s),
    'ecosistema', (select jsonb_object_agg(k,c) from (
        select coalesce(ecosistema,'—') k, count(*) c from public.icone_diagnosticos_eco group by 1) s),
    'membresias', (select coalesce(jsonb_object_agg(item,c),'{}'::jsonb) from (
        select jsonb_array_elements_text(membresias) item, count(*) c
        from public.icone_diagnosticos_eco where membresias is not null group by 1) t),
    'tareas', (select coalesce(jsonb_object_agg(item,c),'{}'::jsonb) from (
        select jsonb_array_elements_text(tareas) item, count(*) c
        from public.icone_diagnosticos_eco where tareas is not null group by 1) t),
    'frenos', (select coalesce(jsonb_object_agg(item,c),'{}'::jsonb) from (
        select jsonb_array_elements_text(frenos) item, count(*) c
        from public.icone_diagnosticos_eco where frenos is not null group by 1) t),
    'ya_hecho', (select coalesce(jsonb_object_agg(item,c),'{}'::jsonb) from (
        select jsonb_array_elements_text(ya_hecho) item, count(*) c
        from public.icone_diagnosticos_eco where ya_hecho is not null group by 1) t)
  ) into res;
  return res;
end; $$;

grant execute on function public.get_diagnosticos_eco(text) to anon;
grant execute on function public.delete_diagnostico_eco(text,uuid) to anon;
grant execute on function public.get_stats_eco() to anon;

-- Verificación
select 'OK · tabla icone_diagnosticos_eco lista' as estado,
       (select count(*) from public.icone_diagnosticos_eco) as registros;
